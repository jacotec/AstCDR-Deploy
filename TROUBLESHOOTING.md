# Troubleshooting

Common problems and how to fix them. Check container logs first:

```bash
docker compose ps
docker compose logs -f cdrj-ingest      # data import
docker compose logs -f cdrj-web         # web app / login
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
- Cost warnings only exist for **outbound, answered** calls on a trunk that has a tariff.

**Admin error mails** (ingest offline, source DB unreachable, bad `costs.yaml`, invalid
license) additionally require the **Errors and warnings** checkbox on an **admin**
account — a non-admin ticking it receives nothing. Use `email.admin_alert_to` for
addresses that should always get them.

## Can't log in as the local admin

- The **bcrypt hash** must be in `config.yaml` (raw, in quotes), **not** in `.env`.
  Regenerate and paste it raw:
  ```bash
  docker compose run --rm cdrj-web python -m app.auth.local "MY-PASSWORD"
  ```
- You can log in with the **username or the email** from the config.
- After editing `config.yaml`, apply it: `docker compose up -d`.

## Login works but the session immediately drops

Usually a cookie/TLS mismatch.

- In production, serve AstCDR over **HTTPS** and set `app.base_url` to the `https://`
  URL — secure session cookies then work correctly.
- For a **local HTTP test only**, set `app.cookie_secure: false` in `config.yaml`.
- Make sure your reverse proxy forwards the original scheme/host (the app runs with
  `--proxy-headers`).

## OIDC login fails

- **Redirect/callback mismatch:** the IdP must allow exactly
  `{base_url}/auth/callback`, and `base_url` must match what the proxy serves.
- **Discovery fails:** open the discovery URL in a browser — it must return JSON.
  **Nextcloud** needs `server_metadata_url` set explicitly.
- **User has no admin rights:** include `groups` in `scopes`, check `groups_claim`,
  and put the user in one of `admin_groups`.
- Details and per-provider notes: [OIDC.md](OIDC.md).

## Footer still says "Unregistered Version" after adding a license

- The file must be named **`astcdr.lic`** and sit in the **`license/`** folder next
  to `docker-compose.yml` (i.e. `/opt/astcdr/license/astcdr.lic`).
- Pickup is automatic within a few seconds; if in doubt `docker compose up -d`.
- Make sure the license major version matches the app's major version (a `1`
  license covers `1.x`).
- See [LICENSE.md](LICENSE.md).

## Wrong times / dates

Set `app.timezone` to your IANA zone (e.g. `Europe/Berlin`). It affects both
display and how the date filters interpret day boundaries.

## Trunk column is empty or shows raw names

List your trunks under `trunks.known` and give them friendly names in
`trunks.labels`. See [CONFIGURATION.md](CONFIGURATION.md#trunks--the-trunk-amt-column).

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
