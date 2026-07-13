# User guide

How to read and work with the call journal. This is the day-to-day guide for
everyone using AstCDR; installation and configuration are covered separately
([INSTALL.md](INSTALL.md), [CONFIGURATION.md](CONFIGURATION.md)).

You can switch the interface between **English, German, Spanish and French** with
the language menu in the header; this guide uses the English labels.

---

## Views

The header's left side has a **view switcher** with three views. The **filter row is
identical in every view**, and your current filter (date range, trunks, search …)
**carries over** when you switch — filter once, look at it three ways:

- **List** — the call journal (this guide's main subject).
- **Costs** — the [cost analysis](#cost-analysis) of your outbound calls.
- **Statistics** — [call statistics](#statistics): volume, heatmap, queues, per
  extension and more.

---

## The header

- **Live** — the auto-refresh toggle. When on (green dot), the journal updates
  itself every few seconds, no reload needed. **Click it to pause**: the dot turns
  into a yellow **pause** sign labelled *Paused* and the list freezes on the current
  view — handy when new calls keep pushing the rows down while you read. Click again
  to resume.
- **Sync** — the health of the data pipeline (the ingest that reads calls from your
  PBX). It is a status indicator, not a button:
  - 🟢 **Sync active** — the ingest is up to date; data is current.
  - 🟡 **Sync: building** (spinner) — the ingest is (re)building the cache or catching
    up (e.g. first start, after a cache reset, or after downtime). The journal may be
    incomplete while this runs.
  - 🔴 **Sync offline** — the ingest hasn't reported in for a while; **the data may be
    stale**. See [Troubleshooting](TROUBLESHOOTING.md).
- **Language** (globe) — a menu to pick the interface language: English, German,
  Spanish or French (remembered per user).
- **Theme** (moon/sun) — dark / light / follow the OS.
- **Fullscreen** — hides the header, KPIs and filters to show as many rows as
  possible; a floating button brings them back.
- **Settings** (gear, admins only) — see [Admin settings](#admin-settings).
- **Account** — your name and role, and **Sign out**.

## Key figures (KPIs)

These cards summarize the current filter selection and update live (the last one
appears only when call costs are configured):

| Card | Meaning |
|------|---------|
| **Total calls** | Number of real calls in the selection. |
| **Answered** | Answered calls, with the answer rate in %. |
| **Missed** | Inbound calls that were not answered (voicemail does **not** count as missed). |
| **Avg. ring time** | Average time until answer. |
| **Avg. talk time** | Average conversation length. |
| **Cost** | Total estimated cost of the outbound calls in the selection. Only shown when a tariff file is configured — see [COSTS.md](COSTS.md). |

---

## Filtering

### Date range
Use the **presets** — *Today*, *7 days*, *30 days*, *This month*, *Last month*,
*All* — or pick an exact **from/to** range with the date fields.

### Search field
The search field understands a small query language — plain text, field operators
and boolean logic. It is **tolerant**: if a query doesn't parse, it falls back to a
plain text search, so you always get a result.

Typing does **not** search as you go — so a longer query (`nst:50 UND nst:51`) is
never cut off mid-way. Type the whole thing, then apply it with **Enter** or the
**✓** button at the end of the field (handy on touch devices). The **×** before the
**?** clears the search filter in one tap; the **?** shows a quick syntax reminder.

**Plain text** matches over **all participants** — numbers and names, both sides,
plus the trunk (substring, case-insensitive):
- **`+49221`** — any number containing `+49221`.
- **`Meier`** — any name containing "Meier".
- **`"Meier GmbH"`** — a quoted phrase, matched as one.

**Field operators** target one field (each has a German and an English alias):

| Operator | Matches |
|----------|---------|
| `nst:14` / `#14` | exact **extension** (not a substring) |
| `von:` / `from:` | the **caller** (number or name) |
| `an:` / `to:` | the **callee** (number or name) |
| `amt:` / `trunk:` | the **trunk** |
| `status:` | `answered`/`ok`, `missed`, `voicemail` |
| `richtung:` / `dir:` | `inbound`, `outbound`, `internal` |
| `zone:` | the cost **zone** |

**Combine** with boolean logic:
- **AND** — put terms side by side (implicit), or write `AND` / `UND`.
- **OR** — `OR` / `ODER`.
- **NOT** — a `-` prefix (`-nst:19`) or `NOT` / `NICHT`.
- **Parentheses** to group: `(nst:19 OR nst:21) status:missed`.

Examples:
- `status:missed to:+49221 -nst:19` — missed calls to +49221…, but not extension 19.
- `von:Meier richtung:inbound` — incoming calls from a caller named Meier.
- `(amt:telekom OR amt:easybell) status:answered` — answered calls on either trunk.

The dropdowns and checkboxes below still narrow further — they combine with your
search as **AND**.

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

### Saved filters
Next to the date presets, the **Saved filters** dropdown lets you keep the filter
combinations you use often. Set up any filter (date range, search, extensions,
trunk, direction, checkboxes …), open the dropdown and choose **Save current
filter**, then give it a name. It now appears in the list — click it on any view
(Journal, Costs, Statistics) to apply it there; the **×** next to an entry removes
it. Saving a new filter under an existing name overwrites it.

Saved filters are stored **per user** (server-side, in your preferences), so they
follow you to any browser once you sign in. They deliberately do **not** capture
the page number or the interface language — only the filter itself. Break-glass
local and OIDC users each keep their own set; anonymous access can't save filters.

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
| **Cost / Real cost / Zone / Quota** | Estimated cost of an **outbound** call, if a tariff file is configured — see [COSTS.md](COSTS.md). *Real cost* applies free minutes; *Quota* is the free minutes left this month. |

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
  parties), announcements (📢, the played prompt), IVR menu steps (🎛, which menu, the
  prompt, and the key the caller pressed), park (⏸), conferences, and voicemail (✉) —
  each with its ring and talk timing. Transfers, Follow-Me hops and consultation holds
  appear here too (a caller held for a consultation shows talk → the consult → talk
  again).

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

## Export & printing

The **printer** button in the header exports the **currently filtered** calls — a
dialog lets you pick a format. There's no row selection: the export always contains
exactly what your filter shows (all matches, in the current sort order).

- **CSV** — **every** column, regardless of what's currently shown. UTF-8 with a BOM
  and semicolon-separated, so Excel (incl. German locale) opens it cleanly. Durations
  are in seconds, timestamps in ISO form, costs as plain numbers — ready for pivots.
- **PDF** — a real, downloadable PDF in A4 portrait. It prints the columns you
  currently see (the **All columns** checkbox is respected). Tick **Include call
  details** to expand every call with its full timeline (transfers, parking,
  conference, voicemail, cost breakdown). Each call is a self-contained card that
  never breaks across a page; every page carries your logo, the app title, the
  **active filters in plain text**, and a **Page x/y** footer.
  - If costs are configured, the PDF opens with a **cost overview** right under the
    filter line: **Cost** and **Real cost** per trunk (only trunks that carry costs in
    the current view), plus a **total** row when more than one trunk is billed.

Clicking a format shows a short **spinner** while the file is generated and starts the
download when it's ready — a large PDF (thousands of calls) can take a few seconds.

> The **free-version** cap applies here too: an export contains at most the first 100
> calls. See [LICENSE.md](LICENSE.md).

---

## Paging

At the bottom: the total number of matching calls, a **per page** selector
(100 / 250 / 500) and page navigation.

> In the **free version**, the journal shows at most the 100 most recent calls and
> the engine keeps only the last 30 days. See [LICENSE.md](LICENSE.md).

---

## Cost analysis

The **Costs** view breaks down the cost of your **outbound** calls for the current
filter. Only answered outbound calls incur cost, so this view is outbound-only, and
any direction filter set elsewhere is ignored here. It needs a tariff file — see
[COSTS.md](COSTS.md).

### Key figures
A row of totals for the current filter: **Cost** (gross), **Real cost** (after free
minutes), **Savings** (what the free minutes saved you), **Outbound talk time**, and
the **number of outbound calls**.

### Charts
Three charts: **Cost by month** spans the full width on its own row, with **Real cost
by zone** and **Cost per extension** side by side below it.
- **Cost by month** — gross vs. real cost per month (your "phone bill" over time),
  with a €-axis. Over long date ranges the month labels thin out to stay readable (the
  bars stay monthly — month is the billing unit). Use the **enlarge** button (top-right)
  to open it large in an overlay.
- **Real cost by zone** — where the money goes (National, Mobile, International …).
- **Cost per extension** — gross and real cost per extension, shown as
  `gross / real` next to each bar.

### Breakdown (trunk → zone → extension)
A list you expand in three levels:
- **Trunk** — total duration, cost and real cost.
- **Zone** (expand a trunk) — the same per zone, plus the remaining free-minute
  **quota**. When your date range spans several months there is no single quota
  value, so the **lowest** remaining value in the range is shown (prefixed `min.`).
- **Extension** (expand a zone) — per extension in that zone. The **real cost per
  extension is shared out fairly**, in proportion to each extension's *billed*
  seconds — so the free-minute discount isn't just credited to whoever happened to
  call last.

Each zone and extension row has a **Details** link that jumps to the **List** view
filtered to exactly those calls (that trunk/zone, outbound, answered only). The
active zone filter appears there as a removable **"Zone: …"** pill above the list.

### Export
The **printer** button exports the breakdown for the current filter:
- **PDF** — titled *Cost analysis*: header with your filters, the key figures, the
  three charts, then the fully expanded list. A zone is never split across a page
  break (unless it has more extensions than fit on one page), and the table header
  repeats on every page.
- **CSV** — a flat table mirroring the expanded list: one row per level (with a
  *Level* column) and a totals row on top, ready to pivot in Excel. Charts are
  visual only, so the CSV is the data behind them.

---

## Statistics

The **Statistics** view aggregates the calls in your current filter into key
figures, charts and tables. Unlike Costs, it covers **all directions**, and the
filter-row checkboxes (*Only answered*, *Only missed*, *Only external*, *Show
ignored*) apply here too — so every figure reflects exactly the calls you selected.

### Key figures
Total calls · Answered (with the answer rate) · Missed · average ring time ·
average talk time.

### Call volume over time
A stacked bar chart (inbound / outbound / internal) with an **automatic time unit**:
day, week, month, quarter or year, chosen so the chart stays readable (roughly ≤ 40
bars). To zoom into weekly or daily detail, **narrow the date range** — the chart
re-buckets automatically; the date filter is your zoom control. Labels thin out when
there are many bars. Use the **enlarge** button (top-right) for a large overlay.

### Direction & status
Two donut charts — calls **by direction** and **by status** (answered / missed /
voicemail / other) — each with counts and percentages.

### Ring time
How long callers waited before a call was answered, grouped into `< 5 s`, `5–10 s`,
`10–20 s`, `20–30 s`, `≥ 30 s`.

### Weekday × hour heatmap
A 7 × 24 grid; the darker a cell, the more calls in that weekday/hour — your busy
times at a glance.

### Queues
One row per call queue: **Offered**, **Answered**, **Abandoned** (caller hung up
while waiting), **answer rate**, **Service level** (share answered within 20 s), and
**average wait**. This is the reliable "how well do we answer?" view. A call that
passed through several queues counts at each of them.

### Per extension
Per extension: inbound / outbound / internal counts, answered, average talk, average
ring and total talk time. Note that this counts the extension that **answered** a
call — for parallel-ringing queues that reflects who picked up, not a per-agent
"answer rate" (which folded call data can't give reliably; use the Queues table for
that).

### Top callers / destinations, per trunk
The busiest external **callers** and **destinations**, and a per-**trunk** summary.

### Export
The **printer** button exports the statistics for the current filter:
- **PDF** — titled *Statistics*: header with your filters, the key figures, the
  call-volume chart, the heatmap, horizontal bars for direction/status/ring time,
  then the tables (queues, per extension, top callers/destinations, per trunk).
  A table is never split across a page break unless it is longer than a whole page,
  and the table header repeats on every page.
- **CSV** — one file with a section per block (key figures, volume, queues, per
  extension, top callers/destinations, per trunk); durations are in seconds for easy
  processing. Charts are visual only, so the CSV is the data behind them.

---

## Admin settings

Admins get a **gear** icon in the header:
- **Logo & app icon** — upload your own **logo** (PNG) and browser-tab **icon**
  (PNG or ICO) to brand the app. The logo appears in the header and on the login
  page; without an upload the built-in glyph is used. Max 2 MB per file; reset
  either back to the default anytime.
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
