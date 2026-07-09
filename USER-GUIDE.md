# User guide

How to read and work with the call journal. This is the day-to-day guide for
everyone using AstCDR; installation and configuration are covered separately
([INSTALL.md](INSTALL.md), [CONFIGURATION.md](CONFIGURATION.md)).

You can switch the interface between **English and German** with the language
button in the header; this guide uses the English labels.

---

## The header

- **Live** — shows the auto-refresh is active; the journal updates itself every
  few seconds, no reload needed.
- **EN / DE** — interface language (remembered per user).
- **Theme** (moon/sun) — dark / light / follow the OS.
- **Fullscreen** — hides the header, KPIs and filters to show as many rows as
  possible; a floating button brings them back.
- **Settings** (gear, admins only) — see [Admin settings](#admin-settings).
- **Account** — your name and role, and **Sign out**.

## Key figures (KPIs)

Five cards summarize the current filter selection and update live:

| Card | Meaning |
|------|---------|
| **Total calls** | Number of real calls in the selection. |
| **Answered** | Answered calls, with the answer rate in %. |
| **Missed** | Inbound calls that were not answered (voicemail does **not** count as missed). |
| **Avg. ring time** | Average time until answer. |
| **Avg. talk time** | Average conversation length. |

---

## Filtering

### Date range
Use the **presets** — *Today*, *7 days*, *30 days*, *All* — or pick an exact
**from/to** range with the date fields.

### Search field
Free text over **all participants** of a call — numbers **and** names, on both the
"from" and "to" side, plus the trunk. It's a substring match, so typing part of a
number or name is enough.

- **`+49221`** — finds every call where any number contains `+49221`.
- **`Meier`** — finds every call where any name contains "Meier".
- **`#14`** or **`nst:14`** — special: an **exact extension** match (not a
  substring), so `14` won't also match `140` or `1400`. Use it to see all calls
  involving extension 14.

> Combined boolean queries (AND/OR/NOT across several conditions) are not part of
> the search field today — use the checkboxes and dropdown below to narrow further.

### Checkboxes
- **Answered only** — successful calls.
- **Missed only** — unanswered inbound calls.
- **External only** — calls that involve an external party (via a trunk).
- **Ignored / show hidden** — reveals events normally hidden (door/paging etc.,
  configured under `journal.hide`).

### Extensions dropdown
Pick one or more internal extensions to see only calls that involve them (combined
as OR). Same effect as `#<ext>` in the search field.

All filters live in the **URL**, so a filtered view is shareable and bookmarkable.

---

## The table

Each row is one logical call (all its legs folded together).

### Columns

| Column | Meaning |
|--------|---------|
| **#** | Running number across pages (orientation only). |
| **Time** | Start time of the call. |
| **Direction** | inbound / outbound / internal (with an icon; missed inbound is marked). |
| **Status** | Answered / Missed / No answer / Voicemail / System, plus flags (see below). |
| **From · No. / Name / Location** | Caller number, name, and country/city for external numbers. |
| **To · No. / Name / Location** | Callee number, name, location. |
| **Trunk** | The provider trunk the call went over — the column commercial CTI leaves empty. |
| **Via** | The number the call came in on / went out through, when relevant. |
| **Involved** | The internal extensions that took part. |
| **Ring** | Time until answer. |
| **Talk** | Conversation length. |
| **Hung up** | Who ended the call (caller or an internal party). |
| **Rec** | A red dot if a recording exists for the call. |

Not every column is shown by default — see [Choosing columns](#choosing-columns).

### Status flags
Small badges next to the status show special handling:
- **Queue** — the call passed through a queue.
- **Follow Me** — it was routed by a Follow-Me rule.
- **↪ transferred** — the call was transferred.
- **parked** — the call was parked.

### Sorting
Click a **column header** to sort by it. Click again to flip between ascending and
descending. The active column is highlighted with an arrow (↑/↓). Time is always
the tie-breaker, so the order stays stable.

### Locations (flags)
For external numbers, the *Location* columns show the country flag and — for
landlines — the city, derived offline from the number. Don't recognize a flag? On
desktop hover it for the country name; on mobile tap it.

---

## Call details

Click any row to expand it. The detail view shows:

- **Meta line:** trunk, "Via" number, Follow-Me target, queues, park slot, total
  duration, and the recording marker if present.
- **System / Context:** the announcement/cause and (for admins) the dialplan
  context.
- **Conversation timeline:** the call's segments in order — bridges (↔ between two
  parties), park (⏸), conferences, and voicemail (✉) — each with its ring and talk
  timing. Transfers and Follow-Me hops appear here too.

Click the row again to collapse it. Open rows stay open while the journal
auto-refreshes.

---

## Choosing columns

Open the **Columns** menu to show/hide columns. Your selection and their order are
**saved per user**. Hidden columns keep their position, so re-showing one puts it
back where it belongs.

The **All columns** checkbox temporarily shows every column (keeping your
configured order) without changing your saved selection — handy for a quick full
look or before a wide export.

---

## Paging

At the bottom: the total number of matching calls, a **per page** selector
(100 / 250 / 500) and page navigation.

> In the **free version**, the journal shows at most the 100 most recent calls and
> the engine keeps only the last 30 days. See [LICENSE.md](LICENSE.md).

---

## Admin settings

Admins get a **gear** icon in the header:
- **Hide contexts** — manage which dialplan contexts/destinations are hidden from
  the journal (written back to `journal.hide`).
- **Rebuild cache** — re-derive the journal from the PBX data. Users and settings
  are kept. Do this after an update that changed the reconstruction logic, or after
  activating a license on a previously free instance. (Same as `./reset-cache.sh`
  on the host.)

---

## Tips

- Views are shareable: copy the URL to hand a colleague the exact filtered result.
- Use **Fullscreen** on a wall display or when scanning a long list.
- The **Involved** column and `#<ext>` search are the fastest way to answer
  "what happened on extension N today?".
