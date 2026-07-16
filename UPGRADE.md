# Updating & operations

## Update to a new version

```bash
cd /opt/astcdr
docker compose pull        # fetch the newest image
docker compose up -d       # recreate containers with it
```

The compose file uses the `:latest` tag by default, so `pull` fetches the newest
release. Your data (cache, users, settings) is preserved across updates.

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
