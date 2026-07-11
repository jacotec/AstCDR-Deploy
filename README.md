# AstCDR — Deploy Bundle

A ready-built, containerized **call journal for FreePBX 17 / Asterisk 22** —
including the **trunk column** that commercial CTI solutions leave empty. Call
legs are folded per `linkedid` into one logical row; direction, trunk, ring/talk
time and status are derived. Optional country/city columns for external numbers,
OIDC login, light/dark, fully responsive.

This repo contains **only the startup files** (no sources). The container images
are pulled from the public registry `ghcr.io/jacotec/astcdr` automatically
on start.

## Demo

A live demo is available at **[astcdr.jacotec.de](https://astcdr.jacotec.de)**:

- **Username:** `demo`
- **Password:** `demo`

## Disclaimer

I built this project purely for my own needs, with exactly the features I want
from a CDR app for my own FreePBX boxes. But if you happen to share my taste,
you're more than welcome to use it too. So here's the deal:

When the project is done, it's done — unless I decide I feel like building
something else onto it. If it breaks five years from now because Asterisk changed
something crucial and I've long since wandered off to a different PBX and don't
need it anymore, then it's broken. This is a "I've got a little time on the couch
right now" kind of thing. You're very welcome to report bugs in the Issues;
feature requests I'll probably ignore.

Why isn't it fully open source? Because between the job, the family, and the
thousand things that always need doing, I simply have zero time for it. I'd have
to maintain it, review PRs, discuss proposals. And it's really not my style to
toss a repo out into the world and go, "someone please take care of this — but
don't mess it up for me." When I do have a bit of time for the community, I test a
ton and file issues or feature requests on other exciting projects — but I get to
do that whenever I feel like it and actually have the time. And if that's not the
case for half a year, then it just isn't.

So, in the spirit of honesty: if you're happy to play with it under these terms —
wonderful. The last 30 days and the last 100 calls work with no restrictions.

For every donation of €25 or more, I'll gladly issue a license file that removes
this limit. For details, see [LICENSE.md](LICENSE.md).

<a href="https://buymeacoffee.com/jacotec" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy me a coffee" height="48"></a>

And if you think all of this is lame — I completely understand. In that case, I
can only point you toward another project or a commercial module.

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
| **[COSTS.md](COSTS.md)** | Outbound call cost calculation — the `costs.yaml` tariff file |
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
