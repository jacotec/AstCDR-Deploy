# Updating & operations

## Update to a new version

```bash
cd /opt/astcdr
docker compose pull        # fetch the newest image
docker compose up -d       # recreate containers with it
```

The compose file uses the `:latest` tag by default, so `pull` fetches the newest
release. Your data (cache, users, settings) is preserved across updates.

### Users & roles (version 2.0)

Version 2.0 replaces the fixed *admin/user* split with roles and rights (see
[USER-GUIDE.md → Users & roles](USER-GUIDE.md#users--roles)). Nothing has to be done for
the update, and nobody gains or loses access:

- The role **Benutzer** is created automatically with exactly the rights a normal user
  had before, and applies to everyone signed in.
- Former admins (`auth.oidc.admin_groups`, local `role: admin`) are **superadmins** and
  may still do everything.
- Two things that were tied to the admin role are now rights of their own: **Technical
  details** in the call details (cause number, context, SIP call ID, addresses) and
  **admin warning emails** (right *Settings*). Superadmins have both; give them to others
  through a role if needed.
- New tables (roles, extensions, audit log) are created on start. Like users, they survive
  a cache rebuild.
- **Operator panel** (licensed version, optional): add `panel: enabled: true` to
  `config.yaml`, give the AMI user the read rights `agent` and `system`, and re-run
  `sudo ./setup-db-user.sh` for the names — details in
  [CONFIGURATION.md → panel](CONFIGURATION.md#panel--operator-panel-optional-licensed-version).
  Then give the right *Open panel* to the roles that should see it.

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
3. **Check the firewall.** The web port is now a normal host port and is therefore —
   correctly — governed by the FreePBX firewall (a published Docker port used to bypass
   it). If your reverse proxy's network sits in the **Trusted** zone, it already has
   full access and there is **nothing to do**. From any other zone, add it:
   *Firewall → Custom Services → Create new Service*, protocol **TCP**, single port
   **3000** (or your `WEB_PORT`), zone **Local**.
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

### Optional: the codec capture container (`cdrj-ami`)

Newer bundles contain a fourth service, `cdrj-ami`, for the optional codec & media
capture. Your existing `docker-compose.yml` keeps working without it. To use the
feature, take the new `docker-compose.yml` from the bundle (or copy the `cdrj-ami`
service into yours), then follow
[CONFIGURATION.md → `ami`](CONFIGURATION.md#ami--codec--media-capture-optional). Without a
configured `ami` block the container just idles.

**Codec capture became a licensed feature.** `cdrj-ami` now checks the license itself and
therefore needs the `license` folder, like `cdrj-web` and `cdrj-ingest`. If you already
run `cdrj-ami` with an older compose file, add this line to its `volumes:` (or take the
new `docker-compose.yml` from the bundle), then `docker compose up -d`:

```yaml
      - ./license:/app/license:ro
```

Without it the listener never sees your license and the capture stays off (log:
*Codec capture requires a valid license*).

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
