# Configuration reference

Everything in `config.yaml`, section by section. The shipped `config.example.yaml`
has the same structure with inline comments — this file explains the *why*.

**Secrets** are never written into `config.yaml` directly. Use `${ENV}`
placeholders that are resolved from `.env` at start (e.g.
`password: "${SOURCE_DB_PASSWORD}"`). Both `config.yaml` and `.env` are gitignored.

---

## `app`

```yaml
app:
  base_url: "https://cdr.example.com"
  secret_key: "${APP_SECRET_KEY}"
  timezone: "Europe/Berlin"
  session_lifetime_minutes: 0
  # cookie_secure: false
```

| Key | Meaning |
|-----|---------|
| `base_url` | **Required.** Public URL where users reach AstCDR. Also the base for the OIDC callback (`{base_url}/auth/callback`). Must match what the reverse proxy serves. |
| `secret_key` | Signs session cookies. Generate once: `openssl rand -hex 32`. Changing it logs everyone out. |
| `timezone` | IANA name. Controls how timestamps are displayed, how day boundaries for date filters are interpreted, and the timestamps in the container logs (a container does not inherit the host timezone — without this they would be UTC). |
| `session_lifetime_minutes` | `0` = no timeout (until logout / browser close). `>0` = auto-logout after N minutes of session age. |
| `cookie_secure` | Omit in production: `Secure` cookies are automatic when `base_url` is `https`. Set `false` **only** for a direct HTTP test without a TLS proxy. |

---

## `source_db` — the FreePBX database (READ ONLY)

```yaml
source_db:
  # socket: "/var/run/mysqld/mysqld.sock"
  host: "10.0.0.5"
  port: 3306
  name: "asteriskcdrdb"
  user: "cdrjournal_ro"
  password: "${SOURCE_DB_PASSWORD}"
```

- **Same host as FreePBX?** Uncomment `socket:` and point it at the MariaDB socket.
  This is the most robust option (no network, no `bind-address`/firewall juggling).
  The compose file already mounts the host socket into the ingest container.
- **Different host?** Remove/omit `socket:` and set `host`/`port`. MariaDB must
  listen on that address (`bind-address`) and the firewall must allow it.
- `user` is the read-only account from `setup-db-user.sh`. AstCDR only ever runs
  `SELECT` against `cdr` and `cel`.

---

## `cache_db` — the Postgres cache

```yaml
cache_db:
  host: "${CACHE_DB_HOST:-127.0.0.1}"
  port: ${CACHE_DB_PORT:-5432}
  name: "cdrjournal"
  user: "cdrjournal"
  password: "${CACHE_DB_PASSWORD}"
```

The bundled Postgres container. It runs **locally and listens on `127.0.0.1` only** —
it is never reachable from your network, and it needs no firewall rule. **Leave these
values as they are** and only set `CACHE_DB_PASSWORD` in `.env`. The cache is
rebuildable (see [UPGRADE.md](UPGRADE.md)); it holds the reconstructed journal plus
users and their preferences.

| Key | Meaning |
|-----|---------|
| `host` / `port` | Written as `${ENV}` on purpose, so the **same `config.yaml` works for both compose variants** (see below). Don't hardcode a host here. |
| `CACHE_DB_PORT` | Set it in `.env` **only if port 5432 is already taken** on this host (e.g. you already run a Postgres). The compose file and this config both follow that value. |

---

## Where AstCDR runs: host mode (default) vs. isolated

The default `docker-compose.yml` uses **`network_mode: host`**: the containers use the
machine's network stack directly — no Docker bridge, no NAT, no iptables rules. That is
the right choice when AstCDR runs **on the FreePBX itself**, which is the normal case:

- A **`fwconsole restart` can't cut AstCDR off the network.** It rewrites the firewall
  and wipes Docker's iptables chains; with host mode there are none to wipe.
- **The web port is governed by the FreePBX firewall.** A *published* Docker port is
  DNAT'd and bypasses the firewall completely — it stays reachable no matter what your
  zones say. In host mode it's an ordinary port and the firewall applies.

Which means the firewall now decides who reaches the UI. Clients whose network is in the
**Trusted** zone already have full access to every port — nothing to do. From any other
zone, assign the port:

> **Firewall → Custom Services → Create new Service**
> Name `AstCDR`, protocol **TCP**, single port **3000** (your `WEB_PORT`), zone **Local**

Only **one** inbound port is ever needed: the web UI. Postgres is loopback-only, and the
ingest worker listens on nothing at all.

### The isolated variant (optional)

`docker-compose.isolated.yml` keeps the classic Docker bridge network and publishes the
web port. **You don't need it for the normal setup** — it exists for two cases:

- AstCDR runs on a **different host** than the PBX (then reach the PBX database over
  TCP: use `source_db.host`/`port` instead of `source_db.socket`), or
- you deliberately don't want host mode (e.g. port 3000 or 5432 is already taken).

Use it by replacing the normal file:

```bash
mv docker-compose.yml docker-compose.host.yml
mv docker-compose.isolated.yml docker-compose.yml
docker compose up -d
```

Your `config.yaml` stays **unchanged** — the isolated compose points the cache at the
container network itself. Be aware of the trade-offs: the published port **bypasses**
the FreePBX firewall (put something in front of it), and if it runs on the PBX, a
firewall reload will cut the containers off until `systemctl restart docker` (see
[TROUBLESHOOTING.md](TROUBLESHOOTING.md)).

---

## `ingest` — how calls are read in

```yaml
ingest:
  interval_seconds: 15
  lookback_minutes: 10
  batch_size: 5000
  initial_backfill_days: 365
  backfill_chunk_days: 7
  max_open_call_minutes: 240
  heartbeat_stale_seconds: 120
```

| Key | Meaning |
|-----|---------|
| `interval_seconds` | How often the worker polls the PBX for new calls. |
| `lookback_minutes` | Overlap window re-read each cycle so late-arriving call legs are still merged. |
| `batch_size` | Rows fetched per query. |
| `initial_backfill_days` | On the **first** run, how far back to import the whole history. |
| `backfill_chunk_days` | The backfill is done in chunks of this size so it never blocks live ingest and the UI is usable quickly. |
| `max_open_call_minutes` | Longest call guaranteed to be captured in full. While a call is in progress the ingest holds its read window open at the call's start, so a call longer than `lookback_minutes` isn't lost when it ends. The cap stops a never-ending (leaked) channel from holding the window forever. Default 4 h covers normal calls; raise for very long conferences. |
| `heartbeat_stale_seconds` | After this long without an ingest run, the **Sync** badge in the web header switches to *offline* (data may be stale). Kept generous against the poll interval so a longer backfill chunk doesn't trigger a false *offline*. |

---

## `auth` — login

```yaml
auth:
  mode: "both"          # oidc | local | both
  oidc: { ... }
  local: { ... }
  password_policy: { ... }
```

`mode` picks which methods are offered: `local` (local accounts only), `oidc` (SSO
only), or `both`. OIDC also needs its own configuration. With `mode: "oidc"` the
username/password form is gone and local logins are refused — for emergency accounts and
for local users alike. The emergency account is not lost: if your IdP is down, set `mode:
"both"` on the server and run `docker compose up -d --force-recreate cdrj-web` — the
username/password form is back. This needs shell access to the server; if you want the
fallback without that step, keep `both`. Full OIDC walkthrough for Nextcloud/Authentik/Keycloak:
**[OIDC.md](OIDC.md)**.

### `auth.local` — emergency accounts

```yaml
  local:
    superadmin:
      - username: "admin"
        email: "admin@example.com"
        display_name: "Administrator"
        password_hash: "$2b$12$…"
```

- Entries here are **emergency accounts**: every one is a **superadmin** (may do
  everything). They cannot be changed in the app.
- **All other local users** are created in the app — *Admin → Users → + New user*, with
  roles to tick, see [USER-GUIDE.md → Users & roles](USER-GUIDE.md#users--roles). They
  live in the database, change their own password under *Account* and can use *Forgot
  password?* if a role grants it.
- Generate the hash: `docker compose run --rm cdrj-web python -m app.auth.local "MY-PASSWORD"`.
- Enter it **raw**, in quotes — **not** via `.env` (bcrypt hashes contain `$`).
- Login works by **username or email**. The `email` links this account to the same
  person's OIDC login (same email → same identity and preferences).
- Keep at least one emergency account even when using OIDC.
- The former keys `users` (with `role`) and `enabled` stop the start with a hint: rename
  `users` to `superadmin`, drop `role` and `enabled` (see
  [UPGRADE.md](UPGRADE.md#upgrading-from-1x-to-20)).

### `auth.password_policy` — passwords of local users

```yaml
  password_policy:
    min_length: 10      # at least this many characters
    min_upper: 1        # of them uppercase letters (0 = no requirement)
    min_digits: 1       # digits (0 = no requirement)
    min_special: 0      # special characters (0 = no requirement)
```

Applies whenever an admin sets a password and when users change or reset their own. The
forms show the rules. Passwords longer than 72 bytes are refused (bcrypt limit). After
**5 failed sign-ins** within 15 minutes (per login name and per address) each further
attempt has to wait, doubling from 2 seconds up to 5 minutes — there is no hard lockout.

**Forgot password** needs email (`email:` section) and `app.base_url` (the link in the
mail points there). The link on the sign-in page only appears once at least one role has
the right *Forgot password*. The link is valid for one hour and works once; at most one mail per
account every five minutes. Only local users whose roles have the right *Forgot password*
get one — never the emergency accounts.

---

## `trunks` — the trunk (Amt) column

```yaml
trunks:
  known: ["easybell", "telekom", "sipgate"]
  labels:
    telekom: "Telekom"
    easybell: "easybell"
  fallback_nonnumeric_is_trunk: true
```

| Key | Meaning |
|-----|---------|
| `known` | Your trunk names as they appear in the channel data. Used to detect which leg is the external trunk. |
| `labels` | Pretty display names per trunk (channel `Easybell` → shown as configured). |
| `fallback_nonnumeric_is_trunk` | If `true`, a non-numeric peer that isn't a known extension is treated as a trunk. Helps surface trunks you didn't list explicitly. |

---

## `geo` — country/city for external numbers

```yaml
geo:
  region: "DE"
  lang: "de"
```

Offline lookup via libphonenumber (no external calls). `region` is the default
country used to interpret nationally-formatted numbers (e.g. `0221…`); `lang`
sets the language of the location description (landline → city name). Drives the
optional "· Location" columns.

---

## `journal` — hide non-telephony events

```yaml
journal:
  hide:
    contexts: ["door-alle"]
    dst_values: []
```

Some dialplan events aren't real phone calls (door stations, paging, placeholder
destinations). List their `contexts` and/or destination `dst_values` here to hide
them. Applied at **display** time, not during ingest — so admins can toggle
"show hidden" in the GUI without re-reading, and the GUI writes changes back here.

---

## `stats` — statistics page

```yaml
stats:
  top_n: 10
```

| Key | Meaning |
|-----|---------|
| `top_n` | Number of rows in the **Top callers** and **Top destinations** lists on the Statistics page — one value for **both** lists, and it also applies to the statistics **PDF/CSV export**. Range **10–100**; values outside are clamped. Default `10`. |

---

## `email` — SMTP for warning notifications (optional)

Lets the app send cost, quota and admin warnings by email. Optional — omit the
block (or set `enabled: false`) to keep email off. Each recipient gets messages in
their own language.

```yaml
email:
  enabled: true
  host: "smtp.example.com"
  port: 587
  security: "tls"            # tls (STARTTLS) | ssl (implicit) | none
  username: "${SMTP_USER}"   # optional (relays without auth)
  password: "${SMTP_PASS}"   # via ${ENV}; keep secrets out of config.yaml
  from_email: "cdr@example.com"
  from_name: "Call Journal"
  timeout: 10
  admin_alert_to: []         # extra recipients for ADMIN error mails only
```

| Key | Meaning |
|-----|---------|
| `enabled` | Master switch. Email is active only when this is `true` **and** `host` and `from_email` are set. |
| `host` / `port` | Your SMTP server and port (typically 587 for STARTTLS, 465 for implicit SSL, 25 for none). |
| `security` | `tls` = STARTTLS, `ssl` = implicit TLS, `none` = unencrypted. Certificate validation is on for `tls`/`ssl`. |
| `username` / `password` | SMTP credentials. Optional — leave empty for relays that don't authenticate. Use `${ENV}` for the password. |
| `from_email` / `from_name` | Envelope sender and display name. |
| `timeout` | Connection timeout in seconds. A slow/dead server never stalls call ingest. |
| `admin_alert_to` | Extra static recipients that always get **admin error** mails, independent of the per-user checkboxes. Cost/quota mails are per-user only. |

**Admin error mails** fire on a state change (and a short "resolved" mail when it
clears): the data ingest going **offline**, the **source database** becoming
unreachable, **`costs.yaml`** having errors, or an **invalid/expired license**. They go
to admins who ticked *Errors and warnings* on their Account page, plus `admin_alert_to`.

**Recipients.** Each user's address comes from their account: OIDC users bring it
from the login, local users from `auth.local.users[].email`. Users choose which
warnings they want on the **Account** page (envelope icon in the header), which
also has a **Send test email** button to verify the setup. Warning thresholds
themselves are configured per trunk/zone in **[COSTS.md](COSTS.md)**
(`cost_warnings`, `contingent_warnings`).

---

## `ami` — codec & media capture (optional)

Asterisk does not store codecs anywhere in CDR or CEL — they only exist on the live
channel. With this block, the `cdrj-ami` container listens on the **Asterisk Manager
Interface** while calls run and records, per channel: the **codec**, whether Asterisk
**transcodes**, whether media (**SRTP**) and signaling (**TLS**) are encrypted, the
**media path**, the **voice quality** from the RTCP reports (data rate, packet loss,
jitter, round-trip time), and (admins only) the SIP Call-ID and addresses. The capture never
changes anything on the PBX — it only reads (`Getvar`). (The operator panel below uses the
same connection to operate calls — only with the extra write rights you grant it.) Omit the block (or set `enabled: false`)
and AstCDR behaves exactly as without the feature: no column, no detail block, the
container just idles.

> **Licensed version only.** Without a valid license the `ami` block is ignored — AstCDR
> behaves exactly as if it weren't configured, and the `cdrj-ami` log says *Codec capture
> requires a valid license*. Drop a license into `license/` and the capture starts on its
> own within a minute, no restart. See [LICENSE.md](LICENSE.md).

```yaml
ami:
  enabled: true
  host: "127.0.0.1"          # the FreePBX itself (host-mode compose)
  port: 5038
  username: "astcdr"
  password: "${AMI_PASSWORD}"   # via ${ENV}; keep secrets out of config.yaml
  # resample_delay_s: 2
  # late_resample_s: 10
  # ping_interval_s: 30
  # qos: true
```

| Key | Meaning |
|-----|---------|
| `enabled` | Master switch. Capture is active only when this is `true` **and** `host`, `username` and `password` are set. A missing `AMI_PASSWORD` in `.env` leaves it off. |
| `host` / `port` | Where the AMI listens. Host-mode compose (AstCDR on the PBX): `127.0.0.1`. Isolated compose: the PBX address, or `host.docker.internal` if the PBX is the Docker host. |
| `username` / `password` | The AMI user from FreePBX (below). Use `${ENV}` for the password. |
| `resample_delay_s` | Seconds until a channel is sampled a second time after joining a bridge — the transcoding path can settle a moment later. Default `2` (0.5–10). |
| `late_resample_s` | One more, later sample after joining a bridge. It catches a codec the provider renegotiates after the call is answered (e.g. answers with G.722, switches to PCMA a few seconds later); it is stored only if something changed. Default `10` (5–120), `0` turns it off. |
| `ping_interval_s` | Keepalive interval; an unanswered ping triggers a reconnect. Default `30` (5–300). |
| `qos` | Collect the voice quality from the RTCP reports. Default `true`; `false` records codecs only. |

**Create the AMI user in FreePBX** — *Settings → Asterisk Manager Users → Add Manager*:
- **Name** `astcdr`, a strong **secret** (that goes into `AMI_PASSWORD`).
- **Deny** `0.0.0.0/0.0.0.0`, **Permit** `127.0.0.1/255.255.255.255` (host mode). For the
  isolated compose, permit the Docker network instead (e.g. `172.16.0.0/255.240.0.0`).
- **Read:** `call` and `reporting` (`reporting` carries the RTCP reports for the voice
  quality). **Write:** only `reporting` — that is all `Getvar` needs. Do **not** grant
  `call` for write unless you use the operator panel ([below](#panel--operator-panel-optional-licensed-version)):
  it allows hanging up or redirecting calls.
- *Submit* and *Apply Config*.

Then apply it with `docker compose up -d --force-recreate`. The admin settings page
shows whether the listener is connected (see [USER-GUIDE.md](USER-GUIDE.md#settings)).

**What to expect:**
- Codecs exist only **while** a call runs, so there is **no history** — capture starts the
  moment the listener connects. Older calls simply show no codecs.
- No cache rebuild is needed. A rebuild does **not** delete codec data either (it can't
  be re-read from anywhere); data of calls that leave the journal is cleaned up
  automatically.
- Voice quality comes from the RTCP reports both sides exchange about every 5 seconds.
  Very short calls (no report yet) show none, the last seconds before hang-up are not
  covered, and an endpoint that sends no RTCP of its own leaves its side empty — AstCDR
  never fills gaps with zeros. Implausible round-trip times (some phones report broken
  timestamps) are discarded.
- If the listener is disconnected for a while, calls from that period show
  *Codec data not captured* instead of nothing. A rejected login is retried only every
  5 minutes, to keep failed attempts out of the PBX's security log (fail2ban).

## `panel` — operator panel (optional, licensed version)

A live view of the PBX: every extension with its state and current calls (partner,
duration, trunk), queues with waiting callers and members, trunks with their calls,
parking slots and conference rooms. It runs inside the `cdrj-ami` container on the **same
AMI connection and user** as the codec capture, so it needs the `ami` block above. See
[USER-GUIDE.md → Operator panel](USER-GUIDE.md#operator-panel).

```yaml
panel:
  enabled: true
  # meta_refresh_s: 300
  # voicemail_path: /var/spool/asterisk/voicemail
```

| Key | Meaning |
|-----|---------|
| `enabled` | Turns the panel on. Active only with a configured `ami` block and a valid license. |
| `meta_refresh_s` | How often the names of extensions, queues, conference rooms and parking lots are read from the FreePBX database. Default `300` (60–86400). |
| `voicemail_path` | Where the voicemail directory is found **inside the `cdrj-web` container**. Default `/var/spool/asterisk/voicemail` — matches the mount in `docker-compose.yml`, so normally leave it alone. |
| `recordings_path` | Where the call recordings are found inside `cdrj-web` (journal and panel). Default `/var/spool/asterisk/monitor` — matches the mount in `docker-compose.yml`. |

**Voicemail.** `docker-compose.yml` mounts the FreePBX voicemail directory
(`/var/spool/asterisk/voicemail`, or `VOICEMAIL_DIR` from `.env`) **read-only** into
`cdrj-web`: the panel lists and plays messages from there. Marking as heard, deleting and
forwarding go through AMI (`VoicemailMove` / `VoicemailRemove` / `VoicemailForward`, write
right `user`, Asterisk 20.5 or newer) — AstCDR never writes to the directory. FreePBX
keeps it readable for everyone (directories `775`, files `664`), so no extra permissions are
needed. With the isolated compose (AstCDR on another host) there is no voicemail directory
— the panel then shows a note instead of the messages.

**Call recordings.** `docker-compose.yml` mounts FreePBX's recordings
(`/var/spool/asterisk/monitor`, or `RECORDINGS_DIR`) into `cdrj-web` — **read-only** by
default, so recordings can be played and downloaded but not deleted. To allow deleting
from AstCDR set `RECORDINGS_MOUNT=rw` in `.env` and check `ASTERISK_GID` (the group id of
`asterisk`, `getent group asterisk`; FreePBX usually uses 995): the container joins that
group and may remove recordings — it never runs as root. Asterisk creates new day folders
with mode `755` (group may not write), so also set a default ACL once — see
TROUBLESHOOTING.md ("The folder of this recording is not writable"). Who may play, download, delete
or start recordings is set per role (see USER-GUIDE.md). AstCDR lists **all** recordings of
a call (one per file in the CDR); calls ingested by an older version show only the first —
run `./reset-cache.sh` once to rebuild them.

**Extend the AMI user** — *Settings → Asterisk Manager Users → astcdr*:
- **Read:** add `agent` (queue events) and `system` (registration events) — so: `call`,
  `reporting`, `agent`, `system`. Read rights only deliver events; they change nothing.
- **Write:** to **operate** calls from the panel (dial from your desk, hang up, transfer,
  park and unpark), add `originate`, `call`, `agent` and `user` — so: `reporting`,
  `originate`, `call`, `agent`, `user`. Without them the panel still shows everything, but
  every action is refused by Asterisk (the panel then says so). **Starting a recording**,
  switching **do-not-disturb / follow-me** (AstDB `DBPut`/`DBDel`) and **phone control for
  Yealink** (`PJSIPNotify`) from the panel additionally need write `system` — Asterisk files
  its `MixMonitor` action there. `system` is powerful (it also allows reloading or stopping Asterisk), so
  only add it if you want to start recordings from the panel; everything else works
  without it. The AMI user never needs `command` or `config`.
- **Check:** on every connection the panel asks Asterisk (`ListCommands`) which actions
  the AMI user may run. If something is missing, users with the right *Settings* see a
  yellow note at the top of the panel naming the missing write class and the panel
  functions it affects (e.g. *write right "system" — start / stop recording, toggle
  do-not-disturb / follow-me*); the `cdrj-ami` log has a warning too. Missing **read**
  classes cannot be queried this way — if queue or registration states don't update, check
  `agent` and `system` under Read.
- Who may operate what is still decided by AstCDR: the rights *Dial*, *Operate own
  extensions*, *Pickup*, *Operate other extensions* and *Listen in* / *Whisper* /
  *Barge in*, *Operate queues* and *Operate conferences* per role — own extensions for the
  first two (agents pause and log themselves in/out with just the panel right), otherwise
  only what the role may see. Logging in dynamic queue agents reads FreePBX's list of
  allowed dynamic agents from the Asterisk database (`DBGetTree`, covered by `reporting`);
  speed-dial numbers are looked up in the dialplan the same way (`ShowDialPlan`, also
  covered by `reporting`). Extensions can be protected from listening in under *Admin → Extensions*. Every action is recorded in
  the audit log.
- *Submit* and *Apply Config*, then `docker compose up -d --force-recreate`.

**Names (optional, recommended).** Queue, conference-room and parking-lot names, and the
names of extensions without a phone (e.g. a voicemail box), come from the FreePBX database.
Re-run `sudo ./setup-db-user.sh` (answer **Y** to keep the existing password — then it
only adds the missing grants and leaves `.env` alone) — it grants read access to exactly these columns
(never to password columns). For conference rooms this includes `userpin` and `adminpin`:
AstCDR only asks **whether** a room has a PIN (to decide who joins as leader and whether a
caller may be put into the room without the PIN prompt) — the PIN itself is never read or
stored. Without that grant every room counts as PIN-protected. Manually:
`GRANT SELECT (exten, description, userpin, adminpin) ON asterisk.meetme TO 'cdrjournal_ro'@'localhost';` Without it the panel shows
numbers instead of those names; extensions with a phone still get their name from Asterisk.
The same applies to **fax reception**: FreePBX names the fax recipient by its user ID, and
the panel looks up that user's default extension (column grant on `userman_users`: only
`id` and `default_extension`). Without that grant it falls back to an extension whose name
equals the fax recipient's name, if exactly one does.

**Who sees what** is set per role (right *Open panel* and the visibility fields), see
[USER-GUIDE.md → Users & roles](USER-GUIDE.md#users--roles).

**Auto-answer** (your own phone picks up by itself when you dial from the panel) is set up
under *Admin → Extensions*: header templates for the common phone vendors and a setting per
extension. No `config.yaml` key is needed. Actions travel from `cdrj-web` to `cdrj-ami`
through a small table in the AstCDR database (woken up instantly via PostgreSQL `NOTIFY`),
so no extra port or token is involved.

---

## Phone control: answer and hold from the panel (licensed version)

Set up per extension under **Admin → Extensions** — the phone button in the table (grey =
nothing set up, green = set up). The dialog lists the devices currently registered on the
extension with their address and a suggested type; **Use** fills in the entry, you add the
token or password. One entry per phone; with several devices the panel controls the one
chosen next to *I'm at*. Users also need the right *Remote-control own phone* — only for
their **own** extensions.

| Phone | How | What you enter / set on the phone |
|---|---|---|
| **Yealink** (T4x/T5x …) | SIP NOTIFY sent **by Asterisk** (`Event: ACTION-URI`) — works behind NAT too | nothing; *Action URI* must be enabled on the phone (`features.action_uri.enable = 1`, the default). On first use the phone may ask *Allow remote control?* — confirm once on the phone, or set `features.show_action_uri_option = 0`. AMI write `system` needed (`PJSIPNotify`). Tested with T57W, T87W, AX83H and AX86R. **If the phone acknowledges the commands but does nothing** (seen on an AX86R with firmware 180.87.0.15): set `features.show_action_uri_option = 0`. The setting is not in the phone's web interface — import a configuration file with it (*Settings → Configuration → Import CFG Configuration File*) or add it to your provisioning template. |
| **Auerswald COMfortel D series** (firmware 1.4A+) | HTTPS action URL from `cdrj-ami` | IP/DNS name + token. On the phone: *Settings → Access*: enable *Allow Action URLs* and generate a token. |
| **Auerswald COMfortel 1400/2600/3600 IP** | HTTP action URL from `cdrj-ami` | IP/DNS name + the phone's web login (Digest). *Receive Action URLs* must be on (factory default). **Answer only** — these phones have no hold, so the panel shows no hold button for them. |

- **Network:** for the two Auerswald types the `cdrj-ami` container connects **to the
  phone** — it must reach the phone's address (LAN or VPN). Yealink needs no direct
  connection.
- **Credentials** are stored encrypted (key derived from `app.secret_key`) and shown in the
  dialog (eye button) — only admins with the right *Settings* can open it.
- Answer only works while the call rings, hold only during a call, resume only while it is
  held — so the panel never takes an idle phone off the hook.

## Phone books (licensed version)

Set up under **Admin → Phone books** — no `config.yaml` keys. AstCDR reads contacts
(read-only) from up to three global sources and keeps a copy in its own database:

| Source | What you enter |
|---|---|
| **LDAP** (Active Directory, OpenLDAP) | server URL (`ldaps://…` recommended), bind DN + password of a read-only service account (empty = anonymous), base DN, filter (default `(\|(objectClass=person)(objectClass=contact))`), optionally which attributes hold name, company and the work / mobile / home numbers |
| **CardDAV** (e.g. a shared Nextcloud address book) | the URL of the address book itself (Nextcloud: `https://<cloud>/remote.php/dav/addressbooks/users/<user>/<book>/`), user, password / app password |
| **FreePBX Contact Manager** | nothing — only switch it on. Only groups of type *external* are read. Needs the column grants of `setup-db-user.sh` (re-run it after updating). |

- **Test connection** checks a source right away with the values in the form.
- Contacts are synced in the background (default every 15 minutes) by `cdrj-ingest`;
  *Sync now* requests it immediately. Each source shows its contact count or last error.
- **Country and area code** make numbers comparable (`0171 …`, `+49 171 …`, a local number
  without area code). They are pre-filled from `geo.region` and the cost file.
- **Passwords** are stored encrypted in AstCDR's database (key derived from
  `app.secret_key`); the page never shows them again. Changing `secret_key` means
  re-entering them.
- **Own address book:** users with the right *Add/see own phone book* can connect **one**
  CardDAV address book of their own under *Account* — only they see those contacts, and
  they take precedence over the global books.
- **Precedence** for a number found more than once: own book, then LDAP, CardDAV, Contact
  Manager; alphabetical on a tie. A phone-book name is shown instead of the transmitted
  caller name, which stays visible in the call details and the panel tooltip.

**Names on the phones (CallerID Superfecta).** Switch on *CallerID Superfecta* on the same
page and save: it shows an address with a secret token. In FreePBX (*Admin → CallerID
Lookup Sources* / Superfecta) add a source of type **Regular Expressions** with this URL
(`$thenumber` is replaced by FreePBX) and the pattern `(.+)`. On an incoming call the
phones then show the name from the global phone books. The address only answers with
the token and from the allowed addresses (default: the PBX itself); generating a new
token invalidates the old address.

## `ui` — appearance & behavior

```yaml
ui:
  brand_title: "Call Journal"
  page_size: 100
  default_range_days: 7
  live_refresh_seconds: 10
  theme: "auto"         # auto | light | dark
```

| Key | Meaning |
|-----|---------|
| `brand_title` | Title shown in the header and browser tab. |
| `page_size` | Default rows per page (users can change it in the UI). |
| `default_range_days` | Default date range on first load. |
| `live_refresh_seconds` | How often the journal auto-refreshes (client poll). Minimum 3. |
| `theme` | `auto` follows the OS; users can override per session. |

---

## `costs.yaml` — outbound call costs (separate file)

Cost calculation for outbound calls is configured in its **own** file,
`costs.yaml` (next to `config.yaml`), not here. It's optional — without it, cost
calculation is off. Full reference: **[COSTS.md](COSTS.md)**.

---

## Applying changes

`config.yaml` and `costs.yaml` are mounted read-only into the containers. Because
only the file **content** changes (not the container definition), a plain
`docker compose up -d` will **not** restart the containers — they keep the old
config in memory. Force fresh containers:

```bash
docker compose up -d --force-recreate
```

**`costs.yaml` specifically:** the ingest re-reads it automatically (within one poll
cycle), so a tariff change doesn't strictly need a restart — but **existing** calls
keep their old cost until you rebuild the cache (admin: gear → **Rebuild cache**, or
`./reset-cache.sh`). See [COSTS.md](COSTS.md). If you only just **created**
`costs.yaml`, run `docker compose up -d --force-recreate` once so the bind-mount
attaches.

A freshly added **license** file is the exception — it is picked up automatically
without a restart (see [LICENSE.md](LICENSE.md)).
