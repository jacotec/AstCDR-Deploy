# AstCDR — Deploy Bundle

A ready-built, containerized **call journal for FreePBX 17 / Asterisk 22** —
including the **trunk column** that commercial CTI solutions leave empty.

This repo contains **only the startup files** (no sources). The container images
are pulled from the public registry `git.jacotec.de/jacotec/astcdr` automatically
on start.

## Quick start

```bash
git clone https://git.jacotec.de/JaCoTec/AstCDR-Deploy.git /opt/astcdr
cd /opt/astcdr
cp .env.example .env                 # fill in secrets
cp config.example.yaml config.yaml   # adapt to your own FreePBX
docker compose up -d
```

The full guide (read-only DB user, OIDC, break-glass admin, operations) is in
**[QUICKSTART.md](QUICKSTART.md)**.

## Contents

| File | Purpose |
|------|---------|
| `docker-compose.yml` | The three containers (web, ingest, postgres), prebuilt images |
| `.env.example` | Secrets & ports — copy to `.env` and fill in |
| `config.example.yaml` | Instance configuration — copy to `config.yaml` |
| `reset-cache.sh` | Rebuild the call cache (users/settings are kept) |
| `QUICKSTART.md` | Full installation and operations guide |

## Requirements

- Docker + Docker Compose, Linux x86-64.
- Access to the FreePBX MariaDB (local socket or LAN).
- A reverse proxy with TLS in front (recommended).

---
© 2026 by Marco Jakobs
