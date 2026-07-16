# AstCDR — Deploy Bundle

A ready-built, containerized **call journal for FreePBX 17 / Asterisk 22** —
including the **trunk column** that commercial CTI solutions leave empty. Call legs
are folded per `linkedid` into one logical row, so you read calls, not fragments.

This repo contains **only the startup files** (no sources). The container images
are pulled from the public registry `ghcr.io/jacotec/astcdr` automatically
on start.

## Features

**The journal**
- Call legs folded per `linkedid` into **one logical row** — direction, trunk,
  ring/talk time and status derived from `cdr` + `cel`.
- The **trunk column**: which line a call actually came in on or went out over.
- Flags at a glance: queue, Follow-Me, transferred, parked, recording present —
  plus **who hung up**.
- Optional **country/city** for external numbers (offline lookup, no external service).
- Pick which columns you want, and in which order — per user.

**Call details**
- The whole path of a call as a timeline: talk legs, **announcements**, **IVR steps**
  (which menu, which prompt, which key the caller pressed), **park** (with slot),
  **conference**, **voicemail**, **transfers** — including the **consultation** while
  the caller sits on hold.
- Ring and talk time per step, so the numbers add up.

**Filtering & search**
- Date range, extension, direction, "missed only" — plus a search field with field
  operators, `AND`/`OR`/`NOT` and parentheses.
- **Saved filters** per user. The filter lives in the URL, so every view is shareable
  and bookmarkable.

**Cost analysis** (optional)
- Your own tariff file: zones by longest-prefix match, billing increment, **free
  minutes** per zone and month.
- Gross vs. **real** cost (free minutes applied) and the quota left — per call, and as
  a **cost view** with charts and a trunk → zone → extension breakdown.

**Statistics**
- Call volume over time (adapts to the range), weekday × hour heatmap, direction and
  status, ring time, **queues & service level**, per extension, top callers and
  destinations, per trunk.

**Email warnings** (optional)
- A mail when a trunk crosses a **cost threshold** or a **free-minute quota** runs low.
  You set the thresholds; each one fires once per month, not on every call.
- Admins can also be warned when something breaks — ingest offline, PBX database
  unreachable, bad tariff file, invalid license — with a "resolved" mail once it clears.
- Everyone opts in per warning type, and every mail is in the recipient's language.

**Export**
- **PDF** and **CSV** for journal, costs and statistics. The PDF is rendered
  server-side and takes your current filter with it.

**Login & users**
- **OIDC** single sign-on (Nextcloud, Authentik, Keycloak) plus a local break-glass
  admin, with admin/user roles.
- Theme, language, columns and saved filters live **per user on the server** — same
  view on every device.

**Live**
- The journal refreshes itself and new calls slide in highlighted. A **Sync** badge
  tells you whether the pipeline is live, catching up, or stopped.

**Look**
- Four languages (EN/DE/ES/FR), light/dark, responsive down to phone width — and your
  own **logo and app icon**.

**How it reads your PBX**
- **Strictly read-only** on the FreePBX database (`SELECT` only, through its own
  read-only user). Everything is folded into a separate Postgres cache; rebuilding that
  cache never touches your PBX data and keeps users and settings.

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
