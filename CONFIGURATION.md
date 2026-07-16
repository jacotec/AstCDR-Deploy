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
| `timezone` | IANA name. Controls how timestamps are displayed and how day boundaries for date filters are interpreted. |
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
```

`mode` picks which methods are offered: `local` (break-glass only), `oidc` (SSO
only), or `both`. Full OIDC walkthrough for Nextcloud/Authentik/Keycloak:
**[OIDC.md](OIDC.md)**.

### `auth.local` — break-glass admin

```yaml
  local:
    enabled: true
    users:
      - username: "admin"
        email: "admin@example.com"
        display_name: "Administrator"
        password_hash: "$2b$12$…"
        role: "admin"        # admin | user
```

- Generate the hash: `docker compose run --rm cdrj-web python -m app.auth.local "MY-PASSWORD"`.
- Enter it **raw**, in quotes — **not** via `.env` (bcrypt hashes contain `$`).
- Login works by **username or email**. The `email` links this local user to the
  same person's OIDC login (same email → same identity and preferences).
- Keep at least one local admin as a fallback even when using OIDC.

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
