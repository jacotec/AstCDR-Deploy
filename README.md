# AstCDR — Deploy Bundle

A ready-built, containerized **call journal for FreePBX 17 / Asterisk 22** —
including the **trunk column** that commercial CTI solutions leave empty. Call
legs are folded per `linkedid` into one logical row; direction, trunk, ring/talk
time and status are derived. Optional country/city columns for external numbers,
OIDC login, light/dark, fully responsive.

This repo contains **only the startup files** (no sources). The container images
are pulled from the public registry `ghcr.io/jacotec/astcdr` automatically
on start.

## Quick start

```bash
git clone https://github.com/jacotec/AstCDR-Deploy.git /opt/astcdr
cd /opt/astcdr
cp .env.example .env                 # fill in secrets & ports
./setup-db-user.sh                   # create the read-only DB user (writes SOURCE_DB_PASSWORD)
cp config.example.yaml config.yaml   # adapt to your own FreePBX
docker compose up -d
```

Then open your `base_url` in a browser and log in. Full details: **[INSTALL.md](INSTALL.md)**.

## Documentation

| Document | What it covers |
|----------|----------------|
| **[INSTALL.md](INSTALL.md)** | Full installation: prerequisites, read-only DB user, first start, first login |
| **[CONFIGURATION.md](CONFIGURATION.md)** | Complete `config.yaml` reference — every setting explained |
| **[OIDC.md](OIDC.md)** | Single sign-on with Nextcloud, Authentik or Keycloak |
| **[LICENSE.md](LICENSE.md)** | Free vs. licensed limits, activating a license |
| **[UPGRADE.md](UPGRADE.md)** | Updating to a new version, when to rebuild the cache |
| **[USER-GUIDE.md](USER-GUIDE.md)** | Using the journal: filters, columns, sorting, search, call details |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common problems and fixes |

## Contents of this bundle

| File | Purpose |
|------|---------|
| `docker-compose.yml` | The three containers (web, ingest, postgres), prebuilt images |
| `.env.example` | Secrets & ports — copy to `.env` and fill in |
| `config.example.yaml` | Instance configuration — copy to `config.yaml` |
| `setup-db-user.sh` | Creates the read-only MariaDB user AstCDR needs |
| `reset-cache.sh` | Rebuild the call cache (users/settings are kept) |
| `license/` | Drop your `astcdr.lic` here to unlock the full version |

## Requirements

- Docker + Docker Compose, Linux x86-64.
- Access to the FreePBX MariaDB (local socket or LAN).
- A reverse proxy with TLS in front (recommended).

---
© 2026 by Marco Jakobs
