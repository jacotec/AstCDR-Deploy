# Updating & operations

## Update to a new version

```bash
cd /opt/astcdr
git pull                   # fetch the new startup files (compose, scripts, docs)
docker compose pull        # fetch the newest image
docker compose up -d       # recreate containers with it
```

`git pull` updates the files next to the compose file — `docker-compose.yml`,
`setup-db-user.sh`, `reset-cache.sh`, the examples and the docs. Your own `config.yaml`,
`costs.yaml`, `.env` and `license/` are not touched. **Don't skip it:** a new release can
need a new compose file or new database grants, and the image alone doesn't bring them.
(Installed from the tarball instead of `git clone`? Unpack the new tarball and copy those
files over yours.)

The compose file uses the `:latest` tag by default, so `pull` fetches the newest
release. Your data (cache, users, settings) is preserved across updates.

## Upgrading from 1.x to 2.0

Version 2.0 brings roles and rights, the **operator panel**, voicemail, call recordings and
phone books. The journal keeps working as before; the update itself is the usual `pull` and
`up -d`. A few one-time steps unlock the new parts:

1. **Take the new `docker-compose.yml`** — `git pull`, or from the bundle (it replaces
   yours). It mounts the FreePBX voicemail and recordings directories read-only into
   `cdrj-web` and contains the `cdrj-ami` container for the panel. If you changed your
   compose file, carry those changes over. Then `docker compose up -d --force-recreate`.
2. **Re-run `sudo ./setup-db-user.sh`** on the PBX and answer **Y** to keep the existing
   password — it only adds the new column grants (names of queues, conference rooms and
   parking lots, PIN flags of conference rooms, Contact Manager) and leaves `.env` alone.
3. **Operator panel** (licensed version, optional): set up the AMI user and add
   `panel: enabled: true` to `config.yaml` — see
   [CONFIGURATION.md → `panel`](CONFIGURATION.md#panel--operator-panel-optional-licensed-version).
   Then give the right *Open panel* (and the operating rights you want) to the roles that
   should use it, and assign users their extensions under *Admin → Users*.
4. **Recordings:** AstCDR now keeps **all** recordings of a call. Run
   `./reset-cache.sh` once so older calls get them too.
5. **Phone books and phone control** are set up in the app: *Admin → Phone books* and the
   phone button under *Admin → Extensions* (see CONFIGURATION.md).
6. **Local login in `config.yaml`** — required, otherwise the start stops with a hint.
   Under `auth.local`, rename `users:` to `superadmin:`, delete each `role:` line and
   delete `enabled:`. Entries in `superadmin` are emergency accounts and always
   superadmins; other local users are now created in the app (*Admin → Users → + New
   user*). Whether local login is offered is set by `auth.mode` alone. Optionally add
   `auth.password_policy` (see
   [CONFIGURATION.md](CONFIGURATION.md#authpassword_policy--passwords-of-local-users)).
   ```yaml
   auth:
     local:
       superadmin:
         - username: "admin"
           email: "admin@example.com"
           password_hash: "$2b$12$…"
   ```

### Users & roles

Version 2.0 replaces the fixed *admin/user* split with roles and rights (see
[USER-GUIDE.md → Users & roles](USER-GUIDE.md#users--roles)). Nothing has to be done for
the update, and nobody gains or loses access:

- The role **Benutzer** is created automatically with exactly the rights a normal user
  had before, and applies to everyone signed in.
- Former admins (`auth.oidc.admin_groups`, local `role: admin` — now
  `auth.local.superadmin`) are **superadmins** and may still do everything.
- Two things that were tied to the admin role are now rights of their own: **Technical
  details** in the call details (cause number, context, SIP call ID, addresses) and
  **admin warning emails** (right *Settings*). Superadmins have both; give them to others
  through a role if needed.
- New tables (roles, extensions, audit log, phone books) are created on start. Like users,
  they survive a cache rebuild.
- All rights for the new functions (panel, voicemail, recordings, phone books) start
  **unticked** in every role — nobody sees them until you grant them.

### What else changes

- **Start page:** users with the panel right now land on the panel. The journal moved to
  `/journal` (the *List* tab); bookmarks of the bare address open the panel for them,
  links with filters (`/?…`) still open the journal.
- **Deleting recordings** from AstCDR is off by default (read-only mount); enable it with
  `RECORDINGS_MOUNT=rw` in `.env` (see CONFIGURATION.md).
- **AMI write rights:** the codec capture still only needs write `reporting`. The panel
  needs more to operate calls — exactly which, and what `system` is needed for, is listed in
  [CONFIGURATION.md → `panel`](CONFIGURATION.md#panel--operator-panel-optional-licensed-version).
  Without them the panel only shows, and tells admins what is missing.

## Older one-time changes (1.x)

Only relevant if you update an installation older than these changes; a fresh 2.0 install already has them.

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

## Pin a fixed version instead of `:latest`

To stay on a specific version (and update only deliberately), set in `.env`:

```bash
CDRJ_IMAGE=ghcr.io/jacotec/astcdr:2.0.0
```

Then `docker compose up -d`. Bump the number when you want to move up.

The same line brings you back to an older release — for example when your license covers
updates only until a certain date and a newer release says so in the footer (see
[LICENSE.md](LICENSE.md#scope-of-a-license)). Going back is safe: updates only ever add
tables and columns, an older release ignores them.

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
- The **Postgres volume** — the call cache itself can always be rebuilt from the PBX,
  but some data cannot: **users and their preferences, roles, extension assignments, the
  audit log, phone-book and phone-control settings, personal phone books** and the
  **codec data** (captured live, nowhere else stored). A dump covers all of it:
  `docker compose exec cdrj-postgres pg_dump -U cdrjournal cdrjournal > astcdr.sql`.

## Restart / logs / status

```bash
docker compose ps                       # container status
docker compose logs -f cdrj-ingest      # ingest / backfill progress
docker compose logs -f cdrj-web         # web app
docker compose restart cdrj-web         # restart a single service
```

More: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
