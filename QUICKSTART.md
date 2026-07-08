# AstCDR — Quick Start (prebuilt images)

A containerized call journal for **FreePBX 17 / Asterisk 22** — with the trunk
column that commercial CTI solutions leave empty.

This bundle contains **no sources**, only the deploy files. The container images
are pulled from the public registry.

## Requirements
- Docker + Docker Compose on the same host as FreePBX (or with network/socket
  access to its MariaDB), Linux x86-64.
- A reverse proxy with TLS in front (HAProxy/nginx/Traefik) — recommended.

## 1. Get the files
```bash
git clone https://git.jacotec.de/JaCoTec/AstCDR-Deploy.git /opt/astcdr
cd /opt/astcdr
cp .env.example .env                 # secrets & ports
cp config.example.yaml config.yaml   # adapt to your own PBX
```
_(Alternatively: download the release tarball from the Releases page and extract it.)_

## 2. Create the read-only DB user (script)
The app reads **only** (no write access to the PBX database). Run on the FreePBX host:
```bash
sudo ./setup-db-user.sh
```
It prompts for a password (or generates a safe one), creates `cdrjournal_ro`
idempotently, and offers to write `SOURCE_DB_PASSWORD` into your `.env`.

<details><summary>Manual alternative (SQL)</summary>

```sql
CREATE USER 'cdrjournal_ro'@'localhost' IDENTIFIED BY 'A-PASSWORD';
GRANT SELECT ON asteriskcdrdb.cdr TO 'cdrjournal_ro'@'localhost';
GRANT SELECT ON asteriskcdrdb.cel TO 'cdrjournal_ro'@'localhost';
FLUSH PRIVILEGES;
```
</details>

## 3. Configure
- **`.env`**: `APP_SECRET_KEY` (e.g. `openssl rand -hex 32`), `CACHE_DB_PASSWORD`,
  `WEB_PORT`, optionally `OIDC_CLIENT_SECRET`. (`SOURCE_DB_PASSWORD` is already set
  if you let the script write it.)
- **`config.yaml`**: `base_url`, `source_db` (socket or host/port), `auth`
  (local break-glass admin and/or OIDC), trunk labels. For a first HTTP test set
  `cookie_secure: false`.
- Generate a **bcrypt hash** for the local admin:
  ```bash
  docker compose run --rm cdrj-web python -m app.auth.local "MY-PASSWORD"
  ```
  Put the hash **raw** into `config.yaml` under `auth.local.users[].password_hash`
  (NOT into `.env` — bcrypt hashes contain `$`, which Compose would eat).

## 4. Start
```bash
docker compose up -d
docker compose logs -f cdrj-ingest    # watch the backfill
```
Then open the `base_url` in a browser and log in.

## License (optional)

AstCDR is donationware. **Without a license** it runs with limits: the journal
shows at most the **100 most recent** calls and the ingest fetches at most the
**last 30 days**. The footer shows *Unregistered Version*.

**With a license** all limits are removed. To activate:
1. Put your `astcdr.lic` into the **`license/`** folder (next to `docker-compose.yml`).
2. **Recreate** the containers so they read the license:
   ```bash
   docker compose down && docker compose up -d
   ```
   (A plain `docker compose up -d` does **not** recreate unchanged containers, so the
   new license would not be picked up.)
3. If this install ran as the **free version** before, rebuild the cache so the full
   history is fetched (the free version only keeps the last 30 days):
   ```bash
   ./reset-cache.sh
   ```

The footer then reads *Licensed for &lt;name&gt;, &lt;email&gt; - Main Version N.x*.
A license is tied to the **major version** (a `1` license covers all `1.x`).

## Operations
- **Rebuild the cache** (only the call data; users/settings are kept) — as an
  admin via the gear icon → "Rebuild cache", or:
  ```bash
  ./reset-cache.sh
  ```
  Do **not** use `docker compose down -v` — that also deletes users/settings.
- **Update** to a new version: set `CDRJ_IMAGE` in `.env` to the new tag, then
  `docker compose pull && docker compose up -d`.
