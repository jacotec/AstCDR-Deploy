# Updating & operations

## Update to a new version

```bash
cd /opt/astcdr
docker compose pull        # fetch the newest image
docker compose up -d       # recreate containers with it
```

The compose file uses the `:latest` tag by default, so `pull` fetches the newest
release. Your data (cache, users, settings) is preserved across updates.

### ⚠️ One-time: the containers now use host networking

**Breaking change.** AstCDR used to run in Docker's own bridge network and publish the
web port. It now uses **`network_mode: host`** — the containers use the PBX's network
stack directly. Why: a `fwconsole restart` used to wipe Docker's iptables rules and cut
the containers off (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)), and the published
port bypassed the FreePBX firewall entirely. Host mode fixes both.

**What you must do when updating an existing installation:**

1. **Take the new `docker-compose.yml`** from this bundle/repo (it replaces yours).
2. **Fix `cache_db.host` in your `config.yaml`.** The service name `cdrj-postgres` no
   longer exists — there is no compose network anymore:
   ```yaml
   cache_db:
     host: "${CACHE_DB_HOST:-127.0.0.1}"   # was: "cdrj-postgres"
     port: ${CACHE_DB_PORT:-5432}
   ```
   (Plain `host: "127.0.0.1"` works too. If you leave `cdrj-postgres`, web and ingest
   can't find the cache and won't start.)
3. **Open the web port in the FreePBX firewall.** It is now a normal host port and is
   therefore — correctly — governed by the firewall:
   *Firewall → Custom Services → Create new Service*, protocol **TCP**, single port
   **3000** (or your `WEB_PORT`), zone **Local**. Without this your reverse proxy can no
   longer reach it.
4. `docker compose up -d`

Nothing else changes: same image, same `.env`, same data. Your cache, users and
settings are untouched.

> **Port 5432 already in use** on this host (another Postgres)? Set `CACHE_DB_PORT` in
> `.env` — compose and `config.yaml` both follow it.
>
> **Don't want host mode**, or running AstCDR on a *different* host than the PBX? Use
> `docker-compose.isolated.yml` — see [CONFIGURATION.md](CONFIGURATION.md).

### One-time: switch the MariaDB socket mount to the directory

Only relevant if you connect through the **Unix socket** (`source_db.socket` in
`config.yaml`). Older bundles mounted the socket **file**:

```yaml
- /var/run/mysqld/mysqld.sock:/var/run/mysqld/mysqld.sock   # old
```

A file mount binds the inode, so after a MariaDB restart or upgrade the container keeps
pointing at the deleted socket and the ingest never reconnects (Sync stays *offline*,
"Connection refused" forever). Change it in your `docker-compose.yml` to the
**directory**:

```yaml
- /var/run/mysqld:/var/run/mysqld                            # new
```

then `docker compose up -d`. From then on a MariaDB restart heals by itself. Don't add
`:ro` — connecting to a Unix socket needs write permission. Not relevant for TCP
connections.

### Pin a fixed version instead of `:latest`

To stay on a specific version (and update only deliberately), set in `.env`:

```bash
CDRJ_IMAGE=ghcr.io/jacotec/astcdr:1.0.3
```

Then `docker compose up -d`. Bump the number when you want to move up.

## When to rebuild the cache

The **cache** holds the reconstructed journal derived from your PBX data. It is
rebuildable at any time — **users, preferences and settings are kept**.

Rebuild it when:
- an update changed the **reconstruction logic** (release notes will say so), or
- you just switched from the **free to the licensed** version and want the full
  history (the free version only keeps 30 days).

Two ways:
- **In the app:** as an admin, gear icon → **Rebuild cache**.
- **On the host:**
  ```bash
  ./reset-cache.sh
  ```

> ⚠️ **Never** use `docker compose down -v`. The `-v` deletes the volumes,
> including **users and settings**. Use `reset-cache.sh` (or the in-app button),
> which clears only the call data.

## Backups

Worth backing up:
- **`config.yaml`** and **`.env`** — your configuration and secrets.
- The **`license/`** folder — your `astcdr.lic`.
- Optionally the **Postgres volume** — but the call cache can always be rebuilt
  from the PBX; only **users and their preferences** are not reproducible, so if
  you back up anything from the DB, that's the part that matters.

## Restart / logs / status

```bash
docker compose ps                       # container status
docker compose logs -f cdrj-ingest      # ingest / backfill progress
docker compose logs -f cdrj-web         # web app
docker compose restart cdrj-web         # restart a single service
```

More: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
