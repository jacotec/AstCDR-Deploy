# Installation

Step-by-step setup of AstCDR from the prebuilt images. Plan for ~15 minutes.

> This bundle contains **no sources**, only the deploy files. The container images
> are pulled from the public registry on start.

## Prerequisites

- **Docker + Docker Compose**, Linux x86-64.
- Access to the FreePBX **MariaDB** — either on the **same host** (local socket,
  simplest) or over the LAN (host/port; mind `bind-address` and firewall).
- A **reverse proxy with TLS** (HAProxy / nginx / Traefik) in front — recommended
  for production. For a first local test you can run plain HTTP (see step 4).

## 1. Get the files

```bash
git clone https://github.com/jacotec/AstCDR-Deploy.git /opt/astcdr
cd /opt/astcdr
cp .env.example .env                 # secrets & ports
cp config.example.yaml config.yaml   # adapt to your own PBX
```

_(Alternative: download the release tarball from the Releases page and extract it.)_

## 2. Create the read-only database user

AstCDR reads the PBX database **only** — it never writes to it. Create a dedicated
read-only user. On the **FreePBX host**:

```bash
sudo ./setup-db-user.sh
```

The script prompts for a password (or generates a safe one), creates the
`cdrjournal_ro` user **idempotently** (safe to re-run, survives FreePBX updates),
grants `SELECT` on the `cdr` and `cel` tables only, and offers to write
`SOURCE_DB_PASSWORD` into your `.env`.

<details><summary>Manual alternative (SQL)</summary>

Local socket (same host):
```sql
CREATE USER 'cdrjournal_ro'@'localhost' IDENTIFIED BY 'A-PASSWORD';
GRANT SELECT ON asteriskcdrdb.cdr TO 'cdrjournal_ro'@'localhost';
GRANT SELECT ON asteriskcdrdb.cel TO 'cdrjournal_ro'@'localhost';
FLUSH PRIVILEGES;
```
For network access replace `'localhost'` with `'%'` (and make sure MariaDB's
`bind-address` and your firewall allow it).
</details>

## 3. Fill in secrets — `.env`

Edit `.env`:

| Variable | Meaning |
|----------|---------|
| `WEB_PORT` | Host port for the web UI (default `3000`). Your reverse proxy talks to this. |
| `APP_SECRET_KEY` | Session signature. Generate: `openssl rand -hex 32`. |
| `CACHE_DB_PASSWORD` | Password for the bundled Postgres cache (choose any). |
| `SOURCE_DB_PASSWORD` | Password of `cdrjournal_ro` (already set if the script wrote it). |
| `OIDC_CLIENT_SECRET` | Only if you use OIDC login — see [OIDC.md](OIDC.md). |

> **Never** put the break-glass admin's bcrypt hash into `.env` — bcrypt hashes
> contain `$`, which Docker Compose interprets as variables and corrupts. It goes
> **raw into `config.yaml`** (next step).

## 4. Configure the instance — `config.yaml`

The minimum you must set (full reference: **[CONFIGURATION.md](CONFIGURATION.md)**):

- **`app.base_url`** — the public URL where users reach AstCDR (also the OIDC
  callback base). For a first HTTP-only test, also set `app.cookie_secure: false`.
- **`source_db`** — how to reach the FreePBX DB: either uncomment `socket:` (same
  host) or set `host:`/`port:`.
- **`auth`** — at least one login method. The simplest start is a local
  break-glass admin:
  ```bash
  docker compose run --rm cdrj-web python -m app.auth.local "MY-PASSWORD"
  ```
  Put the printed bcrypt hash **raw** into `config.yaml` under
  `auth.local.users[].password_hash`.
- **`trunks.known` / `trunks.labels`** — your trunk names, so the trunk column
  shows friendly labels.

## 5. Start

```bash
docker compose up -d
docker compose logs -f cdrj-ingest    # watch the initial backfill
```

The ingest worker fills the cache from your PBX history (chunked, so the UI is
usable quickly and the rest streams in). Open your `base_url` and log in.

## 6. First login

- **Local admin:** the username/password from step 4.
- **OIDC:** click the login button — see [OIDC.md](OIDC.md) for the IdP setup.

## Next steps

- **[USER-GUIDE.md](USER-GUIDE.md)** — how to use filters, columns, sorting, search.
- **[LICENSE.md](LICENSE.md)** — remove the free-version limits.
- **[UPGRADE.md](UPGRADE.md)** — keeping AstCDR up to date.
- Problems? **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**.
