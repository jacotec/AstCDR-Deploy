# Troubleshooting

Common problems and how to fix them. Check container logs first:

```bash
docker compose ps
docker compose logs -f cdrj-ingest      # data import
docker compose logs -f cdrj-web         # web app / login
docker compose logs -f cdrj-ami         # codec capture & operator panel (only if enabled)
```

---

## `docker compose pull` says `unauthorized`

The images are public, but a pull can still fail if you are logged in to the
registry with an account that lacks access, or the registry requires sign-in.

- Try an anonymous pull: `docker logout ghcr.io` then `docker compose pull`.
- Check your internet/proxy can reach `ghcr.io`.

## No calls appear / the journal stays empty

Almost always the **ingest** can't reach the FreePBX database.

1. `docker compose logs -f cdrj-ingest` — look for connection errors.
2. **Same host (socket):** make sure `source_db.socket` is set and the compose
   file mounts the real socket path (default `/var/run/mysqld/mysqld.sock`). If
   your distro's socket is elsewhere, adjust both.
3. **Network (host/port):** MariaDB must listen on that address (`bind-address`)
   and the firewall must allow it. Test from the host:
   `mysql -h <ip> -u cdrjournal_ro -p asteriskcdrdb -e "SELECT COUNT(*) FROM cdr;"`
4. Verify the read-only user exists and `SOURCE_DB_PASSWORD` in `.env` matches.
   Re-run `./setup-db-user.sh` if unsure (it is idempotent).
5. The first backfill takes a moment — watch the ingest log; rows appear in chunks.

## The **Sync** badge in the header shows *offline* or *building*

The **Sync** badge reflects the ingest (data pipeline), not your browser.

- 🟡 **Sync: building** is normal on first start, right after a cache reset, or while
  catching up after downtime — the cache is filling. It clears on its own once the
  ingest is caught up. If it never clears, watch `docker compose logs -f cdrj-ingest`
  for a stuck backfill.
- 🔴 **Sync offline** means the ingest hasn't reported in for `heartbeat_stale_seconds`
  (default 120 s) — the process is stopped, crashed, or stuck, so **the data on screen
  may be stale**. Check it: `docker compose ps` (is `cdrj-ingest` up?) and
  `docker compose logs -f cdrj-ingest` (errors?). `docker compose up -d cdrj-ingest`
  restarts it. The badge returns to *active* within a poll or two once it runs again.

## After a PBX update, containers can't reach anything (build fails, no OIDC, no emails)

> **Mostly historic.** Since AstCDR runs with `network_mode: host` by default, the
> running containers no longer use Docker's iptables rules at all and are immune to
> this. It still applies if you **build the image yourself** on the PBX (the build does
> use the bridge network), or if you chose `docker-compose.isolated.yml`.

Symptom: the host is perfectly fine (`ping`, `nslookup`, `git pull` all work), but
**inside** a container nothing gets out. Typical signs, in any combination:

- a rebuild dies on `Temporary failure resolving 'deb.debian.org'`,
- with the isolated variant: **OIDC login** stops working and **warning emails** stop
  arriving, while the journal itself keeps working normally.

That last part is the giveaway: Postgres and the PBX database (Unix socket) don't need
the outside world. Only OIDC, SMTP and image builds do.

**Check it** (an IP address, so DNS is not involved):

```bash
docker run --rm alpine ping -c1 1.1.1.1     # 100% packet loss?
iptables -S FORWARD | head                   # only "-P FORWARD DROP" and nothing else?
```

If Docker's chains (`DOCKER-USER`, `DOCKER-ISOLATION-STAGE-1`, …) are missing from
`FORWARD`, that's it.

**Cause:** on a PBX, Docker is not the only thing managing iptables — the FreePBX
firewall manages the same tables. Docker installs its rules **once, when the daemon
starts**, and never re-checks them. When the FreePBX firewall restarts, it rewrites the
tables from scratch and takes Docker's chains with it. Docker also sets
`-P FORWARD DROP` and then relies on *its own* rules to let container traffic back
through — so once those rules are gone, the blanket DROP remains and every container
packet is dropped, silently.

**The trigger is `fwconsole restart`** (it stops and starts the firewall module), not the
update itself. Measured on a live PBX through a full update cycle:

| after | container network | Docker rules in FORWARD |
|-------|-------------------|-------------------------|
| `apt upgrade` | **works** | intact |
| `fwconsole restart` | **dead** | **gone** |
| `systemctl restart docker` | works | restored |

So a plain package upgrade is harmless — it's restarting the firewall that does it.

**Fix:**
```bash
sudo systemctl restart docker
```
Docker rebuilds its chains. Verify with the same `ping` — it must answer.

> Rule of thumb: **after every `fwconsole restart` (or anything else that restarts the
> FreePBX firewall), restart Docker.** Order matters — Docker has to come up *after* the
> firewall. Restarting Docker does **not** harm the firewall's own rules: Docker only
> adds its chains, it never flushes the tables.

## After a MariaDB restart/upgrade the ingest never reconnects

Symptom: your PBX database is back up, `mysql` works fine on the host, but AstCDR
stays on **Sync: offline** and `docker compose logs cdrj-ingest` repeats
`Can't connect to MySQL server ... [Errno 111] Connection refused` forever.

Cause: you're connecting through the **Unix socket** and the compose file mounts the
socket **file**:

```yaml
- /var/run/mysqld/mysqld.sock:/var/run/mysqld/mysqld.sock   # ← the problem
```

A file bind-mount binds the **inode**, not the path. When MariaDB restarts it deletes
and recreates its socket — a **new inode**. The container keeps pointing at the old,
dead one. (That's why it's "connection refused" and not "file not found": from inside
the container the socket still exists, nothing is listening on it.) This never heals on
its own.

**Fix it now:**
```bash
docker compose up -d --force-recreate cdrj-ingest
```

**Fix it for good** — mount the **directory** instead (current bundles already do):
```yaml
- /var/run/mysqld:/var/run/mysqld
```
Then a freshly created socket inside that directory is visible to the container and the
ingest reconnects on its own within a poll cycle. Don't add `:ro` — connecting to a Unix
socket needs write permission. Apply with `docker compose up -d`.

> Not affected if you connect over **TCP** (`source_db.host`/`port` instead of
> `socket`) — there's no socket file in play.

## No warning emails arrive

Always start with the **Send test email** button on your **Account** page (click your
name in the header) — it isolates SMTP from the warning logic.

**The Account page / your name isn't a link at all.** Email isn't active. It needs
`email.enabled: true` **and** `host` **and** `from_email` in `config.yaml`. Anything
missing → the whole section stays hidden.

**The test email fails.** Almost always SMTP itself:
- **Wrong `security` for the port.** `tls` = STARTTLS (usually 587), `ssl` = implicit
  TLS (usually 465), `none` = unencrypted (25). A mismatch typically hangs until the
  `timeout` and then fails.
- **Auth expected but not sent.** If `username` is empty, the app sends **no**
  credentials at all — a relay that requires auth then rejects the mail. Set
  `SMTP_USER`/`SMTP_PASS` in `.env` (they're referenced from `config.yaml` as `${ENV}`).
- **`${SMTP_PASS}` resolves to empty** because the variable isn't in `.env`. The compose
  file loads `.env` into the containers via `env_file`, so after adding it run
  `docker compose up -d` — a **running** container keeps its old environment.
- **Relay restrictions:** many servers only accept a `from_email` belonging to the
  authenticated account, or only from allowed IPs.
- Certificate validation is **on** for `tls`/`ssl` — a self-signed SMTP certificate
  will fail.

The exact reason is logged: `docker compose logs cdrj-web | grep astcdr.notify`
(test mail) or `... logs cdrj-ingest | grep astcdr.notify` (warnings).

> **If email used to work and suddenly stopped after a PBX update**, don't hunt the mail
> server first — check that containers can reach the network at all:
> `docker run --rm alpine ping -c1 1.1.1.1`. A firewall reload can wipe Docker's
> iptables rules and cut SMTP off silently. See
> [above](#after-a-pbx-update-containers-cant-reach-anything-build-fails-no-oidc-no-emails).

**The test email works, but no warnings come.** Then it's not SMTP:
- The **checkbox** for that warning type is off on your Account page (all are off by
  default), or your account has **no email address** (it comes from OIDC or from
  `auth.local.users[].email` — it can't be edited in the app).
- **No thresholds configured**: warnings need `cost_warnings` (per trunk) or
  `contingent_warnings` + `freemin` (per zone) in `costs.yaml`. See [COSTS.md](COSTS.md).
- **The threshold hasn't been crossed yet**, or it **already fired this month** — each
  threshold is sent once per calendar month, not on every call.
- Warnings are only evaluated while the ingest is **caught up** (Sync badge *active*),
  so a running backfill never replays old threshold crossings as fresh mail.
- Cost warnings only exist for **billed outbound legs** (a normal outbound call, or a
  call forwarded out to an external number) on a trunk that has a tariff.

**Admin error mails** (ingest offline, source DB unreachable, bad `costs.yaml`, invalid
license) additionally require the **Errors and warnings** checkbox on an **admin**
account — a non-admin ticking it receives nothing. Use `email.admin_alert_to` for
addresses that should always get them.

## Can't log in as the local admin

- The start stops with *the key "users" was renamed to "superadmin"* (or *remove
  "enabled"*): since 2.0 the emergency accounts are under `auth.local.superadmin`, without
  `role`; whether local login is offered is set by `auth.mode` — see
  [UPGRADE.md](UPGRADE.md#upgrading-from-1x-to-20).
- `auth.mode: "oidc"` hides the local login entirely — set `"both"` (or `"local"`).
- *Too many failed attempts — please try again in … s*: a brake after 5 failed sign-ins;
  wait the time shown.
- The **bcrypt hash** must be in `config.yaml` (raw, in quotes), **not** in `.env`.
  Regenerate and paste it raw:
  ```bash
  docker compose run --rm cdrj-web python -m app.auth.local "MY-PASSWORD"
  ```
- You can log in with the **username or the email** from the config.
- After editing `config.yaml`, apply it: `docker compose up -d`.

## "Forgot password?" is missing or no mail arrives

- The link only appears with local login on (`auth.mode` `local`/`both`), email set up
  (`email:` section) **and** at least one role with the right *Forgot password*.
- A mail is only sent for a **local user from the app** with an **email address** whose
  roles have the right *Forgot password* — never for emergency accounts. The page answers
  the same either way (so it does not reveal accounts); the audit log shows *Password reset
  requested* with "mail sent" or "not sent".
- At most one mail per account every five minutes; the link is valid for one hour and
  points to `app.base_url`.

## Login works but the session immediately drops

Usually a cookie/TLS mismatch.

- In production, serve AstCDR over **HTTPS** and set `app.base_url` to the `https://`
  URL — secure session cookies then work correctly.
- For a **local HTTP test only**, set `app.cookie_secure: false` in `config.yaml`.
- Make sure your reverse proxy forwards the original scheme/host (the app runs with
  `--proxy-headers`).

## The audit log shows the proxy's IP instead of the user's

The web server only believes `X-Forwarded-For` from proxies it trusts — by default only
`127.0.0.1`. If your reverse proxy runs on another host, add its address to `.env`, e.g.
`FORWARDED_ALLOW_IPS=10.32.0.1` (comma list, networks allowed), and restart the stack
(`docker compose up -d --force-recreate`). Only list your proxy: a trusted address can
claim any client IP.

## Operator panel: the *Panel* tab is missing or the panel stays empty

- **Tab missing:** the user's role needs the right *Open panel*, and the instance a valid
  license ([LICENSE.md](LICENSE.md)).
- **Panel empty / "No connection to the PBX":** the panel runs in `cdrj-ami`. Check that
  `config.yaml` has a complete `ami` block **and** `panel: enabled: true`, that `cdrj-ami`
  is running, and look at `docker compose logs -f cdrj-ami` (login refused? wrong
  password? AMI *Permit* not covering the container's address?).
- **A user sees no extensions or no desk:** extensions are assigned to users under
  *Admin → Users*; what else a role may see is set in the role (visibility fields).
- **Queue or registration states don't update:** the AMI user lacks the **read** rights
  `agent` and `system` (see CONFIGURATION.md → panel).

## Operator panel: actions fail ("Asterisk refused: …")

The panel shows everything with read rights alone, but every action needs **write** rights
of the AMI user. Admins with the right *Settings* see a yellow note at the top of the panel
naming the missing write class and the functions it affects. Add it under *Settings →
Asterisk Manager Users* in FreePBX, *Apply Config*, then
`docker compose up -d --force-recreate`. The list of classes and what each is needed for is
in [CONFIGURATION.md → panel](CONFIGURATION.md#panel--operator-panel-optional-licensed-version).

## Dialing from the panel: my phone rings instead of picking up by itself

Auto-answer depends on the phone. Under *Admin → Extensions* choose the header template for
your phone vendor and switch auto-answer on for that extension. Phones that ignore the
header simply ring — pick up yourself; then switch auto-answer off for that extension. With
**all devices** selected next to *I'm at*, every device rings and none answers by itself.

## Phone control: "Answer" / "Hold" does nothing

- **Yealink:** the phone confirms the command but does nothing → set
  `features.show_action_uri_option = 0` on the phone (only possible through a configuration
  file or your provisioning template, not in the web interface) — see
  [CONFIGURATION.md → Phone control](CONFIGURATION.md#phone-control-answer-and-hold-from-the-panel-licensed-version).
  Also check that *Action URI* is enabled (`features.action_uri.enable = 1`) and that the
  AMI user has write `system` (needed for `PJSIPNotify`).
- **Auerswald:** *Phone not reachable* — `cdrj-ami` cannot reach the phone's address (it
  connects **to** the phone; LAN or VPN needed). *The phone rejected the credentials* —
  check the token (COMfortel D) or the web login (COMfortel 1400/2600/3600 IP).
- **"No phone control is set up for this phone":** set it up under *Admin → Extensions*
  (phone button). With several devices on one extension choose the device next to
  *I'm at*.

## Voicemail: "The voicemail storage is not reachable"

The panel reads the messages from the FreePBX voicemail directory, mounted read-only into
`cdrj-web`. Check that your `docker-compose.yml` has the line
`- ${VOICEMAIL_DIR:-/var/spool/asterisk/voicemail}:/var/spool/asterisk/voicemail:ro`
under `cdrj-web` → `volumes` (an older compose file lacks it — take the new one from the
bundle), then `docker compose up -d --force-recreate`. If your PBX keeps voicemail
elsewhere, set `VOICEMAIL_DIR` in `.env`. With the isolated compose (AstCDR on another
host) voicemail is not available. Marking as heard, deleting and forwarding additionally
need the AMI write right `user` (see CONFIGURATION.md → panel).

## Recordings: "Deleting is not enabled" or "File is missing"

*Deleting is not enabled* means the recordings directory is mounted read-only (the
default). Set `RECORDINGS_MOUNT=rw` in `.env`, check `ASTERISK_GID` (`getent group
asterisk`), then `docker compose up -d --force-recreate`.

*The folder of this recording is not writable* although `RECORDINGS_MOUNT=rw` is set:
Asterisk creates each new day folder (`YYYY/MM/DD`) with mode `755` — only the owner
`asterisk` may write there, not the group. (`fwconsole chown` later sets `775`, which is why
older folders work.) Fix it once on the PBX with a default ACL, so every new folder inherits
group write access:

```bash
command -v setfacl || apt install -y acl
setfacl -R -m g:asterisk:rwX /var/spool/asterisk/monitor
setfacl -R -d -m g:asterisk:rwX /var/spool/asterisk/monitor
```

Check: `docker compose exec cdrj-web sh -c 'd=/var/spool/asterisk/monitor/$(date +%Y/%m/%d); touch $d/.t && rm $d/.t && echo OK'`. *File is missing* means the CDR
names a recording that is not (or no longer) in `/var/spool/asterisk/monitor/YYYY/MM/DD/`
— e.g. removed by FreePBX's own cleanup. Starting a recording from the panel is refused by
Asterisk ("Permission denied") until the AMI user has write `system`.

## OIDC login fails

- **Redirect/callback mismatch:** the IdP must allow exactly
  `{base_url}/auth/callback`, and `base_url` must match what the proxy serves.
- **Discovery fails:** open the discovery URL in a browser — it must return JSON.
  **Nextcloud** needs `server_metadata_url` set explicitly.
- **User has no admin rights / the wrong role:** include `groups` in `scopes`, check
  `groups_claim`, and put the user in one of `admin_groups` (superadmin) or in a group a
  role is assigned to. Roles are applied at the next login.
- Details and per-provider notes: [OIDC.md](OIDC.md).

## Footer still says "Unregistered Version" after adding a license

- The file must be named **`astcdr.lic`** and sit in the **`license/`** folder next
  to `docker-compose.yml` (i.e. `/opt/astcdr/license/astcdr.lic`).
- Pickup is automatic within a few seconds; if in doubt `docker compose up -d`.
- Footer says *License for Main Version N.x — not valid for M.x*: an older license without
  an update period only covers its major version (a `2` license covers `2.x`); you need a
  new license for this release.
- Footer says *updates until &lt;date&gt; — this build is from &lt;date&gt;*: your license
  covers updates up to that date, and this release is newer. Nothing is deleted; get a
  new license or pin the previous release (see [LICENSE.md](LICENSE.md#scope-of-a-license)).
- See [LICENSE.md](LICENSE.md).

## Wrong times / dates

Set `app.timezone` to your IANA zone (e.g. `Europe/Berlin`). It affects the display,
how the date filters interpret day boundaries, **and the timestamps in the container
logs** (`docker compose logs`).

> **Careful when querying the cache database by hand.** A container does *not*
> inherit the host timezone. The app connects with `app.timezone`, but a manual
> `psql` session uses the container's zone — so a `WHERE start_ts >= '… 10:15'`
> can silently be off by your UTC offset and return nothing. Either set `TZ` for
> the Postgres container (see `.env.example`) or start the query with
> `SET TIME ZONE 'Europe/Berlin';`.

## AstCDR lists more calls than the FreePBX CDR report

That is expected. FreePBX's CDR report reads the `cdr` table; AstCDR reads the CEL
events, which record every call. With Asterisk's default (`unanswered = no` in
`cdr.conf`), **no CDR is written** for a call that was never answered *and* never reached
another party — typically a phone that hung up within a second, before the PBX dialled
anything (a redial or speed-dial key pressed by accident). AstCDR still shows these calls:
outbound to the dialled number, no trunk, termination *Cancelled by caller*.

## Trunk column is empty or shows raw names

List your trunks under `trunks.known` and give them friendly names in
`trunks.labels`. See [CONFIGURATION.md](CONFIGURATION.md#trunks--the-trunk-amt-column).

## No **Codecs** column / the codec capture doesn't start

0. The codec capture is part of the **licensed version**. Without a valid license the
   `ami` block is ignored (log of `cdrj-ami`: *Codec capture requires a valid license*;
   Admin settings say so too). See [LICENSE.md](LICENSE.md).
1. The column and the detail block only exist when the `ami` block is **configured**:
   `enabled: true` plus `host`, `username` and a non-empty password. Without
   `AMI_PASSWORD` in `.env` the feature stays off — the log of `cdrj-ami` then says
   *Codec capture is off*. After changing it: `docker compose up -d --force-recreate`.
2. `docker compose logs -f cdrj-ami`:
   - *AMI login rejected* — wrong username/password, or the AMI user lacks permissions
     (read `call,reporting`, write `reporting`). Retries only every 5 minutes on purpose.
   - *connection … failed (ConnectionRefusedError)* — wrong host/port, or the AMI user
     doesn't **permit** the address AstCDR connects from. Host mode connects from
     `127.0.0.1`; the isolated compose from the Docker network.
3. Admin settings → *Codec capture (AMI)* shows the current state.

## Codecs are shown, but no voice quality (or only one side)

The values come from the RTCP reports that Asterisk and the endpoint exchange about every
5 seconds during a call:
- **Short calls** (a few seconds) end before the first report — nothing to show.
- **One side "—"**: that endpoint doesn't send RTCP reports (some trunks and phones
  don't), or RTCP is blocked by a firewall/NAT. Asterisk's own measurement (*Asterisk
  receives*) still works.
- **No RTT**: a round-trip time needs a full report exchange; values a phone reports with
  broken timestamps are discarded on purpose.
- `qos: false` in the `ami` block switches the voice quality off entirely.

## TLS shows ✗ or — although the trunk uses TLS

Asterisk's own flag (`CHANNEL(pjsip,secure)`) only looks at the SIP address of the call:
a provider that runs over TLS but sends `sip:…:5061` instead of `sips:` or
`;transport=tls` reads as "not secure". AstCDR therefore also checks the **transport of
the endpoint**: a transport whose name says `tls`/`wss` (FreePBX: `0.0.0.0-tls`) counts as
TLS. ✗ is only shown when both point to unencrypted (`udp`/`tcp`/`ws`); anything else is
**—** (not provable). Calls recorded before this check keep their old value.

## Calls show *Codec data not captured*

The listener was disconnected during those calls (container stopped, PBX restarted,
network gone). Codecs exist only while a call runs, so these calls can't be filled in
later. Calls from before the capture was enabled show no codec information at all.

## I need to start the data over

Rebuild **only the call cache** (users and settings are kept):

```bash
./reset-cache.sh
```

> ⚠️ **Never** run `docker compose down -v`. The `-v` deletes the volumes,
> including **users and settings**.

---

Still stuck? Collect `docker compose logs` for `cdrj-ingest` and `cdrj-web` around
the time of the problem — they name the concrete cause in almost every case.
