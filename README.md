# AstCDR — Deploy Bundle

A ready-built, containerized **call journal and operator panel for FreePBX 17 /
Asterisk 22** — including the **trunk column** that many commercial CTI solutions leave empty.
Call legs are folded per `linkedid` into one logical row, so you read calls, not
fragments. The **operator panel** shows the whole PBX live and lets you dial, transfer,
park and pick up calls from the browser.

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

**Operator panel** (optional, licensed version)
- Every extension live as a tile: state, current calls with partner, duration and trunk —
  plus queues with waiting callers and agents, trunks, parking slots and conference rooms.
- **Operate calls from the browser:** dial from your desk, hang up, transfer, consult,
  park and unpark, pick up, pull a call to your phone — by button, menu or **drag & drop**.
- **Answer and hold** on your own phone (Yealink, Auerswald), reject a ringing call as
  *busy*.
- **Speed dials:** tiles for important numbers — internal ones (a feature code, a
  `Custom:` hint such as a door opener or a spam button) show their live state, external
  ones light up while a call with that number is active. Global ones set by the admin,
  personal ones per user, optionally dialed with a single click.
- **Conference rooms:** join as leader, pull a caller into a room, mute, lock, end.
- **Queues:** pause with a reason, log agents in and out. **Do-not-disturb** and
  **Follow-Me** with a click. **Listen in, whisper, barge in** — each a right of its own.
- **Voicemail** (listen, mark, forward, delete) and **call recordings** (play, download,
  delete, start and stop) — in the panel and in the journal.
- **Phone books:** LDAP, CardDAV, the FreePBX Contact Manager and a personal CardDAV book
  per user — names in the journal and the panel, number suggestions while dialing, and
  caller names on the phones via CallerID Superfecta.
- **Who may do what** is set per role, down to single functions and the extensions a user
  may see; every action lands in the audit log.

**Codecs & media** (optional, licensed version)
- Per call: the **codec** of every leg, a **⚠ transcoding** marker, **HD** voice, whether
  media (**SRTP**) and signaling (**TLS**) were encrypted, and the media path — read live
  from the Asterisk Manager Interface, no dialplan changes.
- **Voice quality** from the RTCP reports: data rate, packet loss, jitter and round-trip time, for both
  directions of every leg.
- Admins get the **SIP Call-ID** with a copy button, to look the call up in a SIP tracer.

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
- **OIDC** single sign-on (Nextcloud, Authentik, Keycloak), **local users** managed in
  the app (roles to tick, password rules, password change, optional *Forgot password*)
  and emergency accounts in the configuration.
- **Roles and rights:** roles of your own, assigned by OIDC group, with fine-grained rights
  (journal scope, costs, export, panel functions, voicemail, recordings, phone books,
  administration) and an **audit log** of every action.
- Theme, language, columns and saved filters live **per user on the server** — same
  view on every device.

**Live**
- The journal refreshes itself and new calls slide in highlighted. A **Sync** badge
  tells you whether the pipeline is live, catching up, or stopped.

**Look**
- Four languages (EN/DE/ES/FR) — by default each user simply gets their **browser's**
  language. Light/dark, responsive down to phone width — and your own **logo and app
  icon**.

**How it reads your PBX**
- **Strictly read-only** on the FreePBX database (`SELECT` only, through its own
  read-only user — on the `cdr` and `cel` tables plus single name columns, never on
  passwords). Everything is folded into a separate Postgres cache; rebuilding that cache
  never touches your PBX data and keeps users and settings.
- The optional **AMI** connection only **reads** for the codec capture. The operator panel
  operates calls through it — but only with the write rights you grant the AMI user, and
  only what each user's role allows.

## Demo

A live demo is available at **[astcdr.jacotec.de](https://astcdr.jacotec.de)**:

- **Username:** `demo`
- **Password:** `demo`

The operator panel in the demo plays a short scripted scenario on a loop — calls ring,
get answered, held, transferred and hung up, a queue caller is served, a voicemail comes
in, a guest joins the conference room. Buttons and menus can be explored, but actions are
not carried out.

## Disclaimer

This project is **donationware**. The licensed version is yours for a donation of
**€50 or more**. The license never expires — the version you run keeps working forever.
**Updates are included for one year**, and every additional **€25** adds another year.
Without a license, AstCDR shows the last 30 days and the 100 most recent calls; the
operator panel, voicemail, call recordings, phone books and the codec capture are part of
the licensed version.

**Why donationware?** I built AstCDR as a private hobby project for my own FreePBX boxes,
to my own requirements — because I wanted a decent call journal and wasn't entirely happy
with FOP2. And I don't want to spend a lot of my private money on commercial alternatives
for my slightly crazy PBX hobby.

I have a family and a job that takes a lot of time and puts food on the table. So I
couldn't look after this properly — neither commercially nor as the maintainer of an
open-source project. It is, and is meant to stay, a hobby project — with no obligations
whatsoever.

<a href="https://buymeacoffee.com/jacotec" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy me a coffee" height="48"></a>

More details: [LICENSE.md](LICENSE.md).

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
| **[USER-GUIDE.md](USER-GUIDE.md)** | Using AstCDR: journal, filters, call details, statistics, costs, operator panel, voicemail, recordings, phone books, users & roles |
| **[USER-GUIDE.de.md](USER-GUIDE.de.md)** | The user guide in German (Benutzerhandbuch) |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common problems and fixes |

## Contents of this bundle

| File | Purpose |
|------|---------|
| `docker-compose.yml` | The containers (web, ingest, postgres, optional AMI container for codec capture and operator panel), prebuilt images, host networking |
| `docker-compose.isolated.yml` | Optional alternative: classic bridge network — only if AstCDR runs on a *different* host than the PBX ([CONFIGURATION.md](CONFIGURATION.md)) |
| `.env.example` | Secrets & ports — copy to `.env` and fill in |
| `config.example.yaml` | Instance configuration — copy to `config.yaml` |
| `setup-db-user.sh` | Creates the read-only MariaDB user AstCDR needs |
| `reset-cache.sh` | Rebuild the call cache (users/settings are kept) |
| `license/` | Drop your `astcdr.lic` here to unlock the full version |

## Requirements

- Docker + Docker Compose, Linux x86-64.
- Access to the FreePBX MariaDB (local socket or LAN) through a read-only user —
  `setup-db-user.sh` creates it.
- For the codec & media details and the operator panel (licensed version, optional): an
  **AMI user** (*Settings → Asterisk Manager Users* in FreePBX). For the codec details it
  only reads (write right `reporting`, nothing that touches calls); the panel needs further
  write rights to operate calls — see
  [CONFIGURATION.md → `ami`](CONFIGURATION.md#ami--codec--media-capture-optional) and
  [→ `panel`](CONFIGURATION.md#panel--operator-panel-optional-licensed-version).
- A reverse proxy with TLS in front (recommended).

## Screenshots

<img width="1782" height="851" alt="image" src="https://github.com/user-attachments/assets/b17bb6e2-bf86-41da-a341-06b78a72baf7" />

<img width="1822" height="935" alt="image" src="https://github.com/user-attachments/assets/6db05475-4c7b-4927-bcb6-4d16670973c3" />

<img width="984" height="795" alt="image" src="https://github.com/user-attachments/assets/318f9fa3-3ff5-4a91-a60b-2a26484908f6" />

<img width="1835" height="937" alt="image" src="https://github.com/user-attachments/assets/8a62cc8a-ae36-4b4f-a4cf-610d9a371955" />

<img width="1837" height="937" alt="image" src="https://github.com/user-attachments/assets/97714353-e306-4bf2-b2cd-7b4330ad0bbe" />

---
© 2026 by Marco Jakobs
