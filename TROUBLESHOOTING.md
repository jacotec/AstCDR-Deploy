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
