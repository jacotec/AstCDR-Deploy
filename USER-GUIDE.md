# User guide

How to work with AstCDR — the call journal, costs, statistics and the operator panel.
This is the day-to-day guide for everyone using AstCDR, plus the admin pages at the end;
installation and configuration are covered separately ([INSTALL.md](INSTALL.md),
[CONFIGURATION.md](CONFIGURATION.md)). A German version is in
[USER-GUIDE.de.md](USER-GUIDE.de.md).

What you see depends on your **rights** (set by an admin in roles, see
[Users & roles](#users--roles)) — a tab or button you have no right for is simply not
there.

Out of the box the interface follows **your browser's language**; you can pin it to
**English, German, Spanish or French** with the language menu in the header. This
guide uses the English labels.

---

## Views

The header has a **view switcher** with up to four views:

- **Panel** — the [operator panel](#operator-panel): the PBX live, and operating calls
  (licensed version, right *Open panel*).
- **List** — the call journal.
- **Costs** — the [cost analysis](#cost-analysis) of your billed calls (right *See costs*).
- **Statistics** — [call statistics](#statistics): volume, heatmap, queues, per
  extension and more (right *Statistics*).

In List, Costs and Statistics the **filter row is identical**, and your current filter
(date range, trunks, search …) **carries over** when you switch — filter once, look at it
three ways.

---

## The header

- **Live** — the auto-refresh toggle. When on (green dot), the journal updates
  itself every few seconds, no reload needed: rows, the KPI cards and the page
  navigator all follow along, so when a new call adds a page you can go straight
  to it. **Click it to pause**: the dot turns
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
- **Language** (globe) — a menu to pick the interface language: **Browser** (the
  default — follows your browser's `Accept-Language`, falling back to English),
  English, German, Spanish or French. Remembered per user.
- **Theme** (moon/sun) — dark / light / follow the OS.
- **Fullscreen** — hides the header, KPIs and filters to show as many rows as
  possible; a floating button brings them back.
- **Install as app** (screen symbol) — only where the browser offers it, see
  [Keyboard, touch and app](#keyboard-touch-and-app).
- **Settings** (gear, only with an admin right) — see [Administration](#administration).
- **Your name** — opens [your account](#your-account); next to it **Sign out**.

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
| **Cost** | Total estimated cost of the billed outbound legs in the selection (incl. calls forwarded out to an external number). Only shown when a tariff file is configured — see [COSTS.md](COSTS.md). |

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
| `via:` / `über:` | the **DDI / inbound number** a call came in over (the *Via* column). Aliases: `vía:`, `ddi:`. |
| `status:` | `answered`/`ok`, `missed`, `voicemail` |
| `richtung:` / `dir:` | `inbound`, `outbound`, `internal` |
| `zone:` | the cost **zone** |
| `codec:` | calls where a channel used that **codec** — `opus`, `g722`, `pcma`/`alaw`, `pcmu`/`ulaw`, `g729` … (also written like the display, e.g. `G.722`) — or `codec:transcoded` (also `transkodiert`, `tc`) for calls Asterisk **transcoded**. Same rule as the *Codecs* column: the latest sample of each channel counts. Needs codec capture (`ami:`). |

**Combine** with boolean logic:
- **AND** — put terms side by side (implicit), or write `AND` / `UND`.
- **OR** — `OR` / `ODER`.
- **NOT** — a `-` prefix (`-nst:19`) or `NOT` / `NICHT`.
- **Parentheses** to group: `(nst:19 OR nst:21) status:missed`.

Examples:
- `status:missed to:+49221 -nst:19` — missed calls to +49221…, but not extension 19.
- `von:Meier richtung:inbound` — incoming calls from a caller named Meier.
- `(amt:telekom OR amt:easybell) status:answered` — answered calls on either trunk.
- `codec:transcoded amt:easybell` — calls on the easybell trunk that Asterisk had to transcode.
- `codec:opus -codec:transcoded` — Opus calls that ran without transcoding.

The dropdowns and checkboxes below still narrow further — they combine with your
search as **AND**.

### Checkboxes
- **Answered only** — successful calls.
- **Missed only** — unanswered inbound calls.
- **External only** — calls that involve an external party (via a trunk).
- **Ignored / show hidden** — reveals events normally hidden (door/paging etc.,
  configured under `journal.hide`, plus the bare feature-code dial when someone
  **picks up** a call — the real call is shown separately with its **PU** flag).

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
| **From · No. / Name / Location** | Caller number, name, and country/city for external numbers. With the panel and the right *Dial*, numbers are underlined: click one for **Call this number** — the panel opens and dials it from your desk. With the right *Add own speed dials* the external number of a call also offers **Save as speed dial**. |
| **To · No. / Name / Location** | Callee number, name, location. For a **missed** inbound call this shows the extension that was rung — the single extension for a direct call, or the originally dialled extension for a Follow-Me. A **queue** call is left empty here (several extensions ring at once, so no single "To"). |
| **Trunk** | The provider trunk the call went over — the column commercial CTI leaves empty. |
| **Via** | The number the call came in on / went out through, when relevant. |
| **Involved** | The internal extensions that took part. |
| **Ring** | Time until answer. |
| **Talk** | Conversation length. |
| **Hung up** | Who ended the call: an internal extension, or the external party — shown as *Caller* on inbound calls and *Callee* on outbound calls. |
| **Rec** | A red dot if a recording exists for the call (hollow: all of them were deleted). With a recordings right (licensed version) click it to open the call's recordings in a sidebar — play, download, delete. |
| **Codecs** | Only with codec capture enabled (see [CONFIGURATION.md](CONFIGURATION.md#ami--codec--media-capture-optional)): the codecs of the call, e.g. *G.722 ↔ Opus*, with **⚠** when Asterisk had to transcode between them. Details are in the call's expanded view. |
| **Cost / Real cost / Zone / Quota** | Estimated cost of the call's billed **outbound leg(s)** — a normal outbound call, or an inbound call forwarded out to an external number — if a tariff file is configured (see [COSTS.md](COSTS.md)). *Real cost* applies free minutes; *Quota* is the free minutes left this month. |

Not every column is shown by default — see [Choosing columns](#choosing-columns).

### Status flags
Small badges next to the status show special handling:
- **Queue** — the call passed through a queue.
- **Follow Me** — it was routed by a Follow-Me rule.
- **↪ transferred** — the call was transferred.
- **parked** — the call was parked.
- **PU picked up** — somebody answered the call from *another* phone (call pickup,
  usually dialled as `**<extension>`). The call detail names the extension it was
  picked up **for**, and that extension is listed under *Involved* — so the call still
  shows up when you filter for the person whose phone actually rang.

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
- **Recordings** (licensed version, with a recordings right): every recording file of the
  call, with a button that opens them in the [recordings sidebar](#recordings); deleted
  ones are listed as *Recording deleted* with who deleted it and when.
- **Termination cause:** why the call ended, in plain language, whenever it's something
  other than a normal hang-up — e.g. *Number not in service*, *User busy*, *Call
  rejected* (from the carrier's ITU-T Q.850 cause). If the caller hung up while dialling,
  before the other side answered, it reads *Cancelled by caller* — the raw carrier cause
  is unreliable in that moment and would only mislead. The same applies when a phone
  hangs up before the PBX even routed the call (e.g. a redial key pressed by accident):
  such a call is listed as *outbound* to the dialled number, without a trunk. With the
  right *Technical details* you also see the raw cause number.
- **Codecs** (with codec capture enabled): the codecs and a **⚠ transcoded** marker. The
  **Details** button opens a window listing each channel — the extension or trunk, its
  codec (**HD** for wideband codecs such as Opus or G.722; **HD↓** when that leg uses a
  wideband codec but only gets narrowband audio — the other party in the same connection
  is narrowband, e.g. PCMA from the trunk, also when the call reached the phone through a
  queue, ring group or Follow-Me, or Asterisk plays an 8 kHz announcement), what
  Asterisk reads and
  writes when it transcodes, whether media (**SRTP**) and signaling (**TLS**) were
  encrypted (✓ / ✗, — if it can't be proven; TLS counts as ✓ when the call's SIP
  address demands it or the endpoint uses a TLS transport such as `0.0.0.0-tls`), and the **media path** (*direct*, *via Asterisk*,
  *conference (mix)*). Below that, **Voice quality (RTCP)** per channel: what
  **Asterisk receives** from that party (measured by Asterisk) and what the **endpoint
  receives** from Asterisk (reported by the endpoint) — the average **data rate**, lost
  packets with the **peak** (worst ~5-second report interval), jitter (average / maximum)
  and the round-trip time (**RTT**). The data rate comes from the sender's own counters
  and needs about 10 s of talk time; depending on the device it includes the RTP header
  or the SRTP checksum, so it can read up to about 5 kbit/s above the pure codec rate
  (e.g. ≈ 68 instead of 64 kbit/s for G.722). A **—** means no report came for that side;
  no values are made up.
  With the right *Technical details* you additionally see the **SIP Call-ID** with a **Copy** button
  — paste it into your SIP tracer (e.g. Homer) — and the signaling and RTP addresses.
  Calls from a period when the listener was disconnected read *Codec data not captured*;
  calls from before the capture was enabled show nothing.
- **System / Context:** the played announcement and (with *Technical details*) the dialplan context.
- **Conversation timeline:** the call's segments in order — bridges (↔ between two
  parties), announcements (📢, the played prompt), IVR menu steps (🎛, which menu, the
  prompt, and the key the caller pressed), park (⏸), conferences, and voicemail (✉) —
  each with its ring and talk timing. Transfers and Follow-Me hops appear here too. When
  an agent puts the caller on hold to ask a colleague before transferring, that
  consultation shows as its own **⟳ Consultation** step (the two staff talking while the
  caller waits on hold) between the caller's legs — so the timing adds up. A transfer to
  a **dialplan destination** (e.g. a Custom Destination that just
  plays an announcement, rather than another extension) shows a **↪ forwarded-to** step
  with the destination it was sent to. Any step that goes **out over a trunk** (a normal
  outbound call, or a leg forwarded to an external number) is tagged **“over &lt;trunk&gt;”**,
  so you can see which trunk carried it — which is also the trunk its cost lands on.
  A call into a **conference room** (FreePBX *Conferences*) shows a **👥 Conference room
  &lt;number&gt;** step: when the caller was in the room, who else was in it at the same
  time, and the talk time — the time spent together with at least one other participant
  (waiting for the leader or recording your name doesn't count). Every participant keeps
  their own call in the journal; the call counts as answered as soon as someone talked in
  the room, and the room number is listed under *Involved*, so filtering for it finds all
  calls into that room.

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
  currently see (the **All columns** checkbox is respected). Each card's header line
  also carries a **Flags** entry naming the status badges of that call (queue,
  Follow Me, transferred, parked, picked up) — so they're in the print even without
  the details. Tick **Include call details** to expand every call with its full
  timeline (transfers, parking, conference, voicemail, IVR and announcement steps,
  consultations, forwards, and the cost breakdown). Each call is a self-contained card
  that never breaks across a page; every page carries your logo, the app title, the
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
> the engine keeps only the last 30 days; the operator panel, voicemail, recordings, phone
> books and the codec & media capture (Codecs column, `codec:` search) are not available.
> See [LICENSE.md](LICENSE.md).

---

## Cost analysis

The **Costs** view breaks down your call costs for the current filter, by **trunk →
zone → extension**. It follows the billed **outbound legs**, so it also covers inbound
calls that were **forwarded out** to an external number (FollowMe/transfer) — each leg
counts on the trunk it actually left over, and on the extension responsible for it
(the one that dialled, or whose forward sent it out). It needs a tariff file — see
[COSTS.md](COSTS.md).

### Key figures
A row of totals for the current filter: **Cost** (gross), **Real cost** (after free
minutes), **Savings** (what the free minutes saved you), **Billed time**, and the
**number of billed legs**.

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
filtered to that trunk/zone. The active zone filter appears there as a removable
**"Zone: …"** pill above the list.

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

## Operator panel

*Licensed version, right **Open panel**, set up as in
[CONFIGURATION.md → panel](CONFIGURATION.md#panel--operator-panel-optional-licensed-version).*
The **Panel** tab (leftmost in the header) shows the PBX live — it updates by itself
within a second. If you have the panel right, the panel is also your **start page** (after
sign-in and when opening the bare address); the journal is under the *List* tab
(`/journal`). Links with filters still open the journal directly.

Right names in *italics* refer to the [rights table](#rights).

### What you see

- **Extensions** as tiles, coloured like the busy lamps on a phone: **green** free,
  **amber** ringing (pulsing), **red** busy, **violet** on hold, **grey** unavailable;
  dashed = a virtual extension without a phone (e.g. a voicemail box, with its count of
  new messages). While a caller is **in the voicemail** of such a box (greeting or
  recording — Asterisk does not tell them apart), or someone **checks the mailbox**, the
  box's tile shows that as a line with the caller and the duration (it may appear up to two
  seconds late: Asterisk reports it on request only). A **fax being received** shows the
  same way on the tile of the fax recipient's extension.
- Every tile has room for **two lines** (calls), so the grid never jumps when calls come
  and go; a third call shows as **+1** in the tile header. Each line shows a coloured dot
  for what is happening (red talking, amber ringing, violet square holding / on hold),
  ↘ incoming / ↗ outgoing, the partner and the duration. Number and name of the partner
  **alternate every 3 seconds**. **Hover over a line** (or focus it with the keyboard) for
  the details: full number and name, the **trunk**, the **queue** if the call came in
  through one, and — once the codec capture has sampled it — the **codec** of the line and
  of the far end, with a note when Asterisk transcodes. Badges in the tile header mark
  **DND**, **FM** (follow-me), a **3-way** call on the phone, an **eye** (someone is
  listening in — only visible to users who may listen in themselves), a small **coffee
  cup** (the extension is paused in at least one queue — hover for which queues and why),
  the envelope **✉** (voicemail) and a red **●** (recordings exist).
- **Your workplace** — the extension you are sitting at — comes first as a double-width
  tile (pin symbol). With more than one own extension (assigned under
  [Users & roles](#users--roles)) choose it under **I'm at** at the left of the toolbar;
  the choice is remembered **per browser** (office PC on one extension, home PC on
  another). With several devices on that extension, choose the device next to it. Your
  other extensions follow, marked with a person symbol; the rest is sorted by **number** or
  **name** (sort button, remembered). The search field filters by extension, name or the
  number of a current call.

- **Speed dials** — important numbers your admin set up (external ones, or internal
  functions such as an announcement) — follow the extensions as tiles with a **star**, sorted
  the same way — except that with sorting by **number** the external ones come last,
  sorted by name. Blue = idle; while a call with that number is active the tile turns amber
  (ringing) or red (talking) and shows which extension has it — an external number is
  recognised in any spelling (`0221 …` = `+49 221 …`). Whether a number is internal is
  looked up in the PBX's dialplan (extensions, hints and custom dialplan such as a
  `*`-code), so a short external number like `112` counts as external; internal numbers
  without a hint show no state. External and long numbers are not shown on the tile — only
  the name; hover for the number. A click works like on an extension tile: *Call*, or *Consult transfer* /
  *Transfer* while you are on the phone; drop a call on it to transfer it there. A speed
  dial set to **Dial directly** (e.g. a door opener) dials at once on a click, without
  asking — during a call the consult/transfer menu stays.
  With the right *Add own speed dials* you add **your own** speed dials under
  [Your account](#my-speed-dials) — they sit among the others, marked with a **person**
  instead of the star, and only you see them. Quicker: **Save as speed dial** in the menu of
  a call line (extension, trunk or queue), of a contact in the contacts sidebar or of a
  dial suggestion — the name is filled in from the phone book or caller ID, tick *Dial
  directly* if you like. On your own speed-dial tile, **Remove speed dial** deletes it.

Below the extensions, three columns (fewer on narrow screens), each scrolling on its own:

- **Queues:** one line per queue with a pill counting its calls (amber while someone is
  waiting). Below it one line per call: **waiting** or **ringing** (with the extensions it
  rings at) first, with position and waiting time, then calls that an agent **answered**
  (⇄ agent) for as long as they last, newest first. Hover over a call for the details. The
  arrow in front of the queue folds the **agents** out (remembered per browser), with their
  state (struck through = paused; **dashed with a sign-in symbol** = logged in dynamically,
  e.g. with `*45`). Changes made in FreePBX show up a few seconds after **Apply Config**;
  the panel also re-checks all queues every 5 minutes.
- **Trunks:** current calls per trunk with the external number and the internal
  extension; hover for direction, number and name, the codecs and whether Asterisk
  transcodes.
- **Parking** and **conference rooms:** each parking lot with its **parking number**
  (where you transfer a call to park it, e.g. `600`) and the slots **in use**, with who is
  parked and for how long. **All** conference rooms of FreePBX with their number, also when
  empty; rooms in use list their participants (leader, muted) — whoever is **talking right
  now** is highlighted in green.

The dot in the header shows the connection: **live**, or *connection to the PBX lost* when
the `cdrj-ami` container cannot reach Asterisk. The page **recovers by itself** — also while
the containers restart during an update; there is no need to reload it. Admins with the
right *Settings* see a **yellow bar** at the top when the AMI user lacks rights for some
panel functions (naming the missing rights and the affected functions).

### The toolbar

The toolbar acts on **your desk** (the extension chosen under *I'm at*) and its **active
call**. Buttons that do nothing right now are greyed out; buttons you have no right for
are not shown. On narrow screens (phone) the toolbar wraps between its three groups.

| Button | What it does | Right |
|---|---|---|
| **Dial field** + green **call** button | Dial a number from your desk (see [Dialing](#dialing-and-answering)). While a call **rings** at your desk and phone control is set up, the button pulses quickly: a click (with the field empty) **answers**. | *Dial* (answering: *Remote-control own phone*) |
| **Contacts** (book) | Opens the contacts sidebar (see [Contacts](#contacts--phone-books)). | *See global phone books* or *Add/see own phone book* |
| **Hang up** (red) | Ends the active call. On a call that is still **ringing** it **rejects** it like the reject key on the phone — the caller gets *busy* (or the busy voicemail). During a consultation it **cancels the consultation** (you are back with the held caller). | *Control own calls* |
| **Hold** (violet) | Puts the active call on hold on your phone; while held the button pulses and another click resumes. Only with phone control set up and a phone that can hold. | *Remote-control own phone (answer, hold)* |
| **Transfer** (blue →) | Blind transfer: type the target or click a tile or a conference room. | *Control own calls* |
| **Consult transfer** (blue ⇄) | Calls the target while the caller waits on hold; the same button then turns green and **completes the transfer**. | *Control own calls* |
| **Park** (amber P) | Parks the active call in the first free slot. | *Control own calls* |
| **Record** (red tape) | Starts or stops recording the active call; pulses while it records. | *Record own calls* |
| **Move into a conference** (violet, three people) | See [Conference rooms](#conference-rooms). | *Control own calls* |
| **Coffee cup** (amber) | Only when your desk is an agent in a queue: **Pause in all my queues** (with a reason) or end the pause; pulses while you are paused — you get no queue calls then. | *Open panel* |
| **Do-not-disturb** (red, minus) | Switches DND of your desk on or off; pulses while on. | *Toggle do-not-disturb of own extensions* |

With **two active calls** (e.g. a 3-way call on the phone) click the call you mean on your
desk tile first — it gets a frame, and the buttons act on that participant only.

Next to the toolbar: the search field, the sort order (number / name), **Normal / Compact**
(smaller tiles, so a switchboard sees more extensions at once; remembered per user), the
**bell** ([notifications](#notifications)) and **?** (legend: the colours of tiles and
dots — round = a person, square = held or a machine such as voicemail or fax — and the
keyboard shortcuts).

### Dialing and answering

- **Dial:** type a number into the field and press Enter or the green call button, or click
  an extension tile and choose *Call*. Your phone rings first; when you pick up, the number
  is dialled (FreePBX's outbound routes and restrictions apply as usual). Typing a
  **conference room** number joins that room (see [Conference rooms](#conference-rooms)).
- **Auto-answer:** your phone picks up by itself if your extension is set up for it under
  [Admin → Extensions](#extensions). It only ever goes to a single device; with *all
  devices* chosen next to *I'm at*, they all ring and you pick up yourself.
- **Suggestions:** while you type, the field suggests extensions (with their state),
  phone-book contacts (by name or company, also when typing letters) and numbers/names from
  the journal (most frequent first, only from calls you may see). A book symbol marks
  phone-book contacts, a small circle numbers from earlier calls. **↑/↓ and Enter dial right
  away; a click asks *Call this number* first** — the extra click guards against calling
  someone by accident. Up to 12 phone-book numbers are suggested; if there are more, the
  last line *All matches in the phone book* opens the contacts sidebar with your search
  filled in.
- **Answer and hold from the panel** (right *Remote-control own phone (answer, hold)*, and
  an admin has set up [phone control](#extensions) for your extension): when a call rings
  at your desk, the green call button pulses quickly — click it with the dial field empty and
  your phone answers. The violet hold button holds and resumes. Phones that cannot hold
  (e.g. Auerswald COMfortel 2600 IP) get no hold button. With several devices on your
  extension, choose the device next to *I'm at* first.
- **Numbers in the journal:** with the panel and the right *Dial*, numbers in the journal
  are underlined — click one for *Call this number*. With the right *Add own speed dials*,
  the external number of a call also offers *Save as speed dial* (name and *Dial directly*
  as in the panel).

### Clicking tiles and calls

A click opens a small menu with what you can do there:

- **A tile** (no call at your desk): *Call* the extension; *Pick up here* while a call
  **rings** there (right *Pick up* — your desk takes the call, with auto-answer right
  away); *Open voicemail*; switch its DND / follow-me (if allowed). A tile with exactly
  **one** call also offers that call's actions; with two calls, click the line you mean.
- **A tile while you are on the phone** offers **Consult transfer** and **Transfer** to
  that extension instead of *Call* (a new call would only reach your phone as a second
  incoming call). Voicemail-only extensions offer *Transfer* only; a conference room offers
  to put the caller **into the room**.
- **Your other own extensions:** click a call line for hang up, transfer, consult
  transfer, park — plus **Take it to me** (the call moves to your desk) and listening in
  (someone else may be using that phone). Right *Control own calls*.
- **Other people's calls** (right *Control other calls*, only extensions your role can
  see): **Take it to me**, **Transfer**, **Park** and **Hang up**.
- **Callers under Trunks, in a queue or in a voicemail box:** **Take it to me** — your
  phone rings first, and only when you pick up is the caller moved to you; if you don't,
  the caller stays where they were. **Redirect call** sends a trunk or queue caller
  somewhere else right away — while it is still ringing, waiting in the queue or listening
  to an announcement: type the target or click a tile. For example click a voicemail box
  tile to send the caller straight to voicemail (or type FreePBX's *Direct Voicemail* code,
  `*` plus the extension, e.g. `*901`). Right *Control other calls*.
- **Parked calls:** click a slot under *Parking* and choose *Pick up at my desk*.
- **Listen in, whisper, barge in** (one right each — none of them is in any role out of
  the box; superadmins have them): on a connected call of another extension, or of one of
  your own extensions other than your desk. After a confirmation your phone rings; when
  you pick up you are listening (keys 4/5/6 switch between listening, whispering and
  barging in). The **eye** on the tile shows that someone is listening. Extensions marked
  *no listening* under [Admin → Extensions](#extensions) never offer it. Every start and
  end is written to the [audit log](#audit-log).
  > **Legal note:** secretly listening in on calls is a criminal offence in many countries
  > (in Germany §201 StGB); in a company data protection law and, where applicable, the
  > works council apply as well. The parties of the call do **not** hear any tone. AstCDR
  > keeps these rights off by default and logs every use — whether and how you may use them
  > is for you to clarify.

The answer appears at the bottom (e.g. *Phone 21 is ringing …* or why Asterisk refused).
Every action is written to the [audit log](#audit-log).

### Drag & drop

Drag a connected call onto a tile to **transfer** it there (hold **Shift** while dropping
for a consult transfer — own extensions only), onto *Parking* to **park** it, onto a
**conference room** to put it into the room, or onto your own desk to **take it**. A caller
from *Trunks*, a queue or a voicemail box dropped on your desk is taken to you, dropped on
any other tile it is **redirected** there. The label at the pointer tells what will happen;
Esc cancels. On touch screens press and hold a call for a moment, then drag. The rights are
the same as for the menus.

### Queues

Fold out a queue's agents and click one to **pause** (with a reason from the list your
admin keeps under [Admin → Extensions](#extensions), or none), **end the pause**, or **log
out** a dynamic agent. An agent in several queues can be paused (or un-paused) **in all
queues** at once — all queues your role can see; others stay untouched. Pausing works for
fixed and dynamic agents alike (a fixed member's pause lasts until the next *Apply Config*,
as in Asterisk); logging in and out only for dynamic ones. Logged-out dynamic agents show as
faint dashed chips — click to **log in**; offered are the queues where FreePBX lists the
extension as a dynamic agent. Your own agent entries need only the panel right; everybody
else's need *Control queues*. For yourself, the coffee-cup button in the toolbar is the
quickest way.

### Conference rooms

- **Join:** click a room (free or busy) and choose **Join conference** — or type the room
  number into the dial field: your phone rings, and when you pick up you are in the room
  (right *Dial*). You join as **leader** if you have the right *Control conferences*, or if
  you open an **empty** room that has **no participant PIN**; otherwise FreePBX handles it
  as usual (PIN prompt, leader only with the admin PIN). Several leaders in one room are
  fine.
- **Put a call into a room:** drag it onto the room, click the room while you are on the
  call (*Into conference room …*), or use the transfer button and then click the room (or
  type its number). The caller joins as a normal participant — never as leader. Into rooms
  with a PIN they get in without the PIN prompt only if you have *Control conferences*;
  otherwise FreePBX asks them for the PIN.
- **Move into a conference** (toolbar, violet button with three people; right *Control own
  calls*): during a call, a consultation, or while your phone holds a three-way call
  itself, it moves everyone into a free conference room: your phone stays on the line
  (nothing rings), the other party (or parties) are put into the room too, and you become
  the room's **leader**. The rooms come from the range under *Admin → Extensions →
  Conference rooms for moving calls* (without it the button is off); the lowest free room is
  used. Use dedicated FreePBX conference rooms without PIN and without "wait for leader",
  not reachable from outside. With a three-way call on the phone, the phone's second line is
  hung up afterwards.
- **Control the room** (right *Control conferences*, or you sit in the room as its leader):
  click a participant to **mute / unmute** or **remove** them; click the room header for
  **mute everyone** / **unmute everyone** (leaders stay audible), **lock / unlock** the room
  (locked: nobody new can join, except leaders) and **end conference** (after a
  confirmation everybody is disconnected, leaders too).

### Do-not-disturb and follow-me

The red button with the minus sign in the toolbar switches **do-not-disturb** of your desk.
For other extensions choose *Switch do-not-disturb on/off* from the tile's menu, or click
the red **DND** badge to switch it off. Extensions whose follow-me lists more targets than
themselves show an **FM** badge: green = on, grey = off; hovering shows the targets, a click
switches it (like `*76` / `*21` on the phone; the phone's BLF keys follow). Rights: *Toggle
do-not-disturb of own extensions* / *… of other extensions* and *Toggle follow-me of own
extensions* / *… of other extensions*.

### Voicemail

Click the envelope **✉** on a tile (with a number when there are new messages; faint when
there are none) or choose *Open voicemail* from the tile's menu. A sidebar opens on the
right with the box's messages — **New** and **Heard**, newest first, each with caller,
time and length. Per message: **▶ play** (player at the top of the sidebar with a wide
slider for seeking, ±5 seconds, speed 1× / 1.5× / 2×), **mark as heard** (or **as new**
again), **forward** to another box you can see (the original stays), **download**, and
**delete** (after a confirmation — it cannot be undone). Playing does **not** mark a message
as heard; only the button does. Heard / new / delete update the counter and the lamp on the
phone right away. Messages stored as GSM cannot be played in the browser — download them
instead.

Rights: *Own voicemail* for the boxes of your own extensions (including virtual ones
assigned to you), *Group voicemail* for virtual extensions without a phone (e.g. a shared
box such as 901) that are not assigned to you, *Other voicemail* for the boxes of all other
extensions your role can see. Playing, downloading, deleting and forwarding are written to
the [audit log](#audit-log).

### Recordings

- **Listen to recordings:** a small red **●** on a tile (or a queue header) means there are
  call recordings for that extension or queue. Click it: the sidebar lists them by day —
  partner, time, length, the extensions involved — with **▶ play** (same player as
  voicemail), **download** and **delete**. In the journal the *Rec* column and the call
  details open the same sidebar for one call. When a call has several recordings (e.g.
  after a transfer), delete asks whether to remove **only this one** or **all recordings of
  the call**. Deleted recordings stay listed in the call details as *Recording deleted*
  with who deleted it and when.
- **Rights** are split nine ways: *Play*, *Download* and *Delete* — each for **own**
  recordings (calls with one of your extensions), **other** recordings (other extensions
  you can see) and **queue** recordings (calls through a queue you can see). A greyed-out
  bin explains why deleting is not possible (e.g. the storage is mounted read-only — see
  TROUBLESHOOTING.md).
- **Missing files:** recordings the CDR names but that are no longer in the storage are
  listed as *File is missing from the storage*; with the delete right the bin removes the
  entry.
- **Record a call** (rights *Record own calls* / *Record other calls*): the record button in
  the toolbar starts or stops recording the active call at your desk; for other calls
  choose *Start recording* / *Stop recording* from the call's menu. A pulsing **tape**
  symbol in front of the partner shows that a call is being recorded — also recordings
  started by FreePBX itself, and also on the calls listed under a queue. Recordings started
  with `*1` on the phone or in the panel can be stopped; recordings a fixed FreePBX rule
  requires (*Call Recording: Force*, e.g. in a queue) cannot — the panel offers no *Stop
  recording* for them. Recordings land in FreePBX's normal storage and show up in the
  journal. Start and stop are written to the audit log.

### Contacts & phone books

*Rights See global phone books and Add/see own phone book; set up by an admin under
[Admin → Phone books](#phone-books).*

- The **book button** right next to the dial button opens the contacts sidebar: search
  field at the top (name, company or number), sort order *Last, first* or *First last*,
  contacts grouped by letter with their numbers (work / mobile / home) and where they come
  from. Click a number and confirm *Call this number* to dial it from your desk.
- Calls show the **name from the phone book** instead of the transmitted caller name — in
  the panel, in notifications and in the journal (list, details, PDF/CSV). The transmitted
  name stays visible in the call details and in the panel tooltip (*Transmitted*). A small
  book symbol marks names from the phone book.
- The journal search finds calls by contact name or company too, even if the call itself
  carried no name.
- **Your own address book:** on your [account page](#your-account) you can connect one
  CardDAV address book (e.g. from your Nextcloud, with an app password). Only you see its
  contacts; they win over the global phone books.

### Notifications

The **bell** in the toolbar sets which events pop up as desktop notifications (Windows
notification area, macOS notification centre): *Call to my extensions*, *Call ringing
elsewhere (can be picked up)* (only with the right *Pick up*), *Unanswered call to my
extensions*, *New voicemail in my mailboxes*, *Caller waiting in one of my queues* — and
whether a notification *stays until I dismiss it*. **Allow notifications** asks the browser
for permission once; **Test notification** shows one right away. Notifications appear while
AstCDR is open (browser tab or installed app) and its window is not in front; clicking one
brings the panel to the front (for voicemail it opens the box). On iPad/iPhone they only
work in the installed app.

### Keyboard, touch and app

- **Keyboard shortcuts** (also in the legend behind **?**): `/` dial field, `F` search,
  `↑`/`↓` choose a suggestion, `Enter` dial, `Esc` close menu or sidebar, `?` legend.
- **Touch (iPad, tablets, phones):** tap a call line or tile to open its menu right away —
  the details a mouse shows on hover (trunk, codec, queue …) are at the top of the menu.
  Buttons are larger on touch screens. A mouse or trackpad works as before.
- **Install as app:** the screen button in the header installs AstCDR as an app (Chrome /
  Edge: own window without address bar, own taskbar icon). On iPad/iPhone it explains the
  way via Safari: *Share → Add to Home Screen* — AstCDR then starts full-screen. This needs
  HTTPS (your reverse proxy); the button only appears where the browser offers it.
- After an **update** to a new version, an open panel and an open journal (while *Live* is
  on) reload themselves once within seconds, so script, styles and the footer match the new
  version. Other pages (statistics, costs, admin pages) show the new version from the next
  click on. When your session has expired, the
  panel takes you to the sign-in page.

---

## Your account

Click **your name** in the header to open your account page.

### Password (local users)

If you sign in with a **local account** (login name or email and password, created by an
admin), you change your password here: current password, new password twice. The page
shows the password rules (by default at least 10 characters, one of them uppercase and
one a digit). After the change you stay signed in on this device; **all other devices are
signed out**.

**Forgot your password?** If email is set up and your admin has given the right *Forgot
password* to at least one role, the sign-in page shows **Forgot password?**. It only
works for you if one of **your** roles has the right: enter your login name or email
and you get a link to set a new password (valid for one hour). The page never says
whether an account exists. Accounts that sign in via SSO (OIDC) change their password at
the identity provider.

### Email notifications

If the operator has set up email (see the operator's `email` configuration), you see the
address that mail goes to (it comes from your account and is read-only here), a **Send test
email** button to confirm delivery, and checkboxes:

- **Cost warnings** — get an email when a trunk's monthly cost crosses a threshold the
  operator configured.
- **Quota warnings** — get an email when a zone's free-minute quota for the month runs
  low (or is used up).
- **Errors and warnings** *(right Settings only)* — get an email when something needs
  attention: the data ingest goes offline, the PBX database becomes unreachable, the
  tariff file has errors, or the license is invalid. A short **resolved** email follows
  once the condition clears.

All emails are in **your** language. Every checkbox is off by default — you opt in.
Warnings are sent once per event (e.g. once per threshold per month), never on every
call. Which trunks/zones have thresholds is set by the operator in the tariff file.

### My address book

With the right *Add/see own phone book* (licensed version) you can connect **one** CardDAV
address book of your own — URL, user and password / app password (Nextcloud:
`https://<cloud>/remote.php/dav/addressbooks/users/<user>/<book>/`). Only you see its
contacts, and they take precedence over the global phone books. It is synced in the
background; the page shows the contact count or the last error.

### This device

With the panel right you find **Keep the screen on while the panel is open** here — for a
tablet on the wall, say. It applies only to the browser you tick it in (your office PC
stays as it is). It needs HTTPS and a browser that supports it: Safari from iOS 16.4 (as a
home-screen app from iOS 18.4), Chrome, Edge. The page says so if yours cannot.

### My speed dials

With the right *Add own speed dials* (licensed version) you keep your **own** speed-dial
tiles here — same table as the admin's (including **Dial directly**): **number** and
**name** per line, an empty line at
the end adds one, the **bin** at the end of a row deletes it (after asking). Only you see them in the panel, after the
extensions together with the global speed dials (with a person symbol instead of the
star); they behave like any speed-dial tile. A number that is already a global speed dial
shows only once. An admin can view and change your list too.

---

## Administration

Users with at least one admin right get a **gear** icon in the header. It opens the first
admin area they may use; tabs at the top switch between **Settings**, **Users & roles**,
**Extensions**, **Phone books**, **Speed dials** and **Audit log** — each tab only with its
right (*Settings* for Settings, Extensions, Phone books and Speed dials). **Back** on these pages (and on your
account page) returns to the page you came from — journal, panel, statistics or costs.

### Settings

*Right Settings.*

- **Logo & app icon** — upload your own **logo** (PNG) and browser-tab **icon**
  (PNG or ICO) to brand the app. The logo appears in the header and on the login
  page; without an upload the built-in glyph is used. Max 2 MB per file; reset
  either back to the default anytime.
- **Ignored calls (contexts & numbers)** — which dialplan contexts and dialled numbers are
  hidden from the journal (one rule per line; written back to `journal.hide`). New calls
  follow immediately; for existing ones rebuild the cache afterwards.
- **Costs / tariffs (costs.yaml)** — the state of the tariff file: trunks with a loaded
  tariff, errors and warnings. **Check config** re-reads `costs.yaml` and shows errors right
  away, without a restart (see [COSTS.md](COSTS.md)).
- **Codec capture (AMI)** — only when enabled: whether the listener is connected, since
  when it is disconnected and why, or that it has stopped sending heartbeats (then check
  the `cdrj-ami` container).
- **Rebuild call cache** — re-derive the journal from the PBX data. Users and settings
  are kept. Do this after an update that changed the reconstruction logic, or after
  activating a license on a previously free instance. (Same as `./reset-cache.sh`
  on the host.)

### Users & roles

*Right Users and roles.*

Who may do what is set in **roles**. A role has a name, an optional **OIDC group** and a
list of **rights**.

- **Rights only add up.** Someone with several roles gets the sum of their rights; there
  is no “deny”.
- The built-in role **Benutzer** applies to **everyone signed in** and cannot be
  deleted. Out of the box it has *Journal: all calls*, *Export*, *See costs* and
  *Statistics*. Change it to change what everybody may do.
- Every other role is given to SSO users through their **OIDC group** at sign-in
  (case-insensitive), and to **local users** by ticking it on the user's page. A changed
  group mapping applies from the next sign-in; changed rights of a role — and roles ticked
  for a local user — apply immediately (an open panel reloads itself within about ten
  seconds, so its buttons and menus match).
- **Superadmins** may do everything without any role: members of
  `auth.oidc.admin_groups` and the **emergency accounts** from the configuration
  (`auth.local.superadmin`). That way you can never lock
  yourself out while setting up roles. The built-in role **Superadmin** (cannot be
  deleted) grants nothing — it only holds what superadmins **see in the panel** (default:
  everything).
- Rights that are added by a later update start **unticked** in every role and are
  marked **new** — an update never grants anything silently.
- Rights of the licensed version are marked **licensed version**: they can be ticked, but
  only take effect with a valid license.

**Visibility in the panel.** Each role can limit which **extensions**, **queues**,
**trunks** (by name) and **speed dials** (by number, as entered) it sees in the
[operator panel](#operator-panel): a comma list of
numbers (`21`), ranges (`20-59`) and prefixes (`7*`); empty means all. A leading minus
**excludes**: `-23,-24` shows everything except 23 and 24, `20-29,-23` shows 20–29 without
23 (also `-20-29`, `-7*`). Several roles add up (whatever one of them shows is visible),
and everybody always sees their own extensions. For superadmins only the **Superadmin**
role counts.

**Users tab.** SSO accounts appear after their first sign-in. Open a user to see their
roles and OIDC groups from the last sign-in and to assign their **own extensions** — also
virtual ones such as a voicemail box. A user with *own calls only* and no extension sees
no calls. **Delete user** removes the account with its extensions and personal settings;
remove an SSO user from your identity provider first, otherwise the next sign-in creates
the account again. You cannot delete your own account. Deleting signs the user out at once.

**Local users.** **+ New user** creates an account that signs in without SSO: **login
name**, **name**, **email** (optional, needed for *Forgot password*) and **password**
(the rules from the configuration apply), plus the **roles** to tick — local users have
no OIDC groups. A local user's page has **Change user** with the same fields; leave the
password empty to keep it. A new password set by the admin signs the user out
everywhere. Login name and email must be unique and must not belong to an emergency
account. If a local user later signs in via SSO with the **same email**, the account
switches to OIDC: the local password is dropped, and the roles then come from the IdP
groups. **Emergency accounts** (marked as such) come from the configuration file and
cannot be changed here.

#### Rights

In the order of the role page. *L* = licensed version only.

| Area | Right | What it allows |
|---|---|---|
| Journal | Journal: own calls only | List, costs and statistics show only calls that involved one of the user's **own extensions**. |
| | Journal: all calls | All calls of the PBX. |
| | Export (CSV/PDF) | Exports of journal, costs and statistics — limited to the journal rights. |
| | See costs | Cost columns, the costs page and costs in printouts. |
| | Technical details | Cause number, dialplan context, SIP call ID and addresses in the call details. |
| Statistics | Statistics | The statistics page — limited to the journal rights. |
| Operator panel *(L)* | Open panel | The panel with the visible extensions, queues and trunks; agents pause and log themselves in/out. |
| | Dial | Dial from your own desk, join conference rooms. |
| | Control own calls | Hang up, transfer, consult transfer, park, take to me, move into a conference — on your own extensions. |
| | Control other calls | Take to me, transfer, park, hang up and redirect on visible extensions of others, trunks and queues. |
| | Pick up | Pick up a ringing call of a visible extension. |
| | Listen in / Whisper / Barge in | One right each. Always logged — mind the legal situation. |
| | Control queues | Pause agents and log them in or out. |
| | Control conferences | Mute or remove participants, lock and end rooms; join as leader; put callers into PIN rooms without the PIN prompt. |
| | Toggle follow-me of own / other extensions | Two rights. |
| | Toggle do-not-disturb of own / other extensions | Two rights. |
| | Remote-control own phone (answer, hold) | Answer, hold and resume on your own desk phone, once phone control is set up. |
| | Add own speed dials | Personal speed-dial tiles under *Account* that only you see. |
| Voicemail *(L)* | Own / Other / Group voicemail | Listen to, mark, forward and delete messages — see [Voicemail](#voicemail). |
| Recordings *(L)* | Play / Download / Delete own, other and queue recordings | Nine rights — see [Recordings](#recordings). Deleting is always logged. |
| | Record own calls / Record other calls | Start and stop recordings in the panel. |
| Phone books *(L)* | See global phone books | Names from LDAP, CardDAV and Contact Manager; contacts sidebar; suggestions. |
| | Add/see own phone book | Connect one own CardDAV address book. |
| Administration | Settings | The Settings, Extensions, Phone books and Speed dials tabs; admin warning emails. |
| | Users and roles | Roles, rights and users' extensions. Whoever has it can grant themselves anything — give it deliberately. |
| | Audit log | The [audit log](#audit-log). |
| Account | Forgot password (local users) | *Forgot password?* on the sign-in page sends the user a link to set a new password (needs an email address on the account and email set up). |

### Extensions

*Right Settings.* Everything about the extensions as the panel uses them:

- **Pause reasons (queues)** — the fixed choice an agent gets when pausing (one per line;
  *no reason* is always offered).
- **Auto-answer templates** — the SIP header the panel sends to your own phone so it picks
  up by itself when you dial from the panel, one template per phone vendor (*Call-Info*
  fits Yealink, Snom, Grandstream and Fanvil). One template is the **Default for all
  others**.
- **Per extension:** which template applies (or *off* for phones that cannot auto-answer),
  **no listening** (the panel never offers listening in, whispering or barging in on this
  extension — e.g. management, works council), and the **Phone** column for phone control.
- **Phone control** — the phone button (grey = not set up, green = set up) opens *Set up
  phone control*: the devices currently registered on the extension with address and a
  suggested type; **Use** fills in an entry, you add the token or password (eye button to
  show it). Types: *Yealink* (via the PBX, nothing to enter), *Auerswald COMfortel D
  series* (address + token) and *COMfortel 1400/2600/3600 IP* (address + web login; answer
  only). Phone-side settings: [CONFIGURATION.md → Phone control](CONFIGURATION.md#phone-control-answer-and-hold-from-the-panel-licensed-version).
- **Conference rooms for moving calls** — *From room* / *To room*: the FreePBX conference
  rooms *Move into a conference* may use (empty = button off).

### Phone books

*Right Settings, licensed version.* The global phone books: country and area code (to make
numbers comparable), the sync interval, and the sources **LDAP**, **CardDAV** and **FreePBX
Contact Manager** — each with **Test connection**, its contact count or last error, and
**Sync now**. Also here: **CallerID Superfecta**, which shows the names from the phone
books on the phones' displays. Field by field:
[CONFIGURATION.md → Phone books](CONFIGURATION.md#phone-books-licensed-version).

### Speed dials

*Right Settings.* Tiles for important numbers in the panel, in two parts:

- **Global speed dials** — for everyone: one line per entry with **number** (external,
  e.g. `+49 221 123456`, or internal, e.g. `666`; digits, `*`, `#`, a leading `+`) and
  **name**. An empty line at the end adds one; the **bin** at the end of a row deletes it (after asking). Which
  speed dials a role sees is set in the role's field *Speed dials* (see
  [Users & roles](#users--roles)). The column **PBX** shows whether the number exists on
  the PBX (*internal*: extension, hint or dialplan — the tile shows its state) or not
  (*external*: the tile lights up during calls with it); *–* = not checked yet (new numbers
  are looked up within half a minute). **Dial directly** makes a click on the tile dial
  without asking — handy for a door opener such as `*833`.
- **Personal speed dials** — the own speed dials of one user (see
  [My speed dials](#my-speed-dials)). Pick the user (the number after the name is how many
  they have) and edit the list the same way. They show in that user's panel only while one
  of their roles has the right *Add own speed dials* — the page says so if not.

Changes are written to the audit log.

### Audit log

*Right Audit log.* Security-relevant actions with time, user, target and IP: role and right
changes, assigned or removed extensions, deleted users, settings changes (hide rules,
branding, cost check, cache rebuild, extensions, phone books, phone control), **rejected
sign-ins** (the entered name, never the password) — and every action in the panel: dialing,
transfers, pickups, listening in, voicemail and recordings (play, download, delete, start,
stop), DND / follow-me, queue and conference control, phone control. Filter by action at the
top. Entries older than one year are removed.

---

## Tips

- Views are shareable: copy the URL to hand a colleague the exact filtered result.
- Use **Fullscreen** on a wall display or when scanning a long list.
- The **Involved** column and `#<ext>` search are the fastest way to answer
  "what happened on extension N today?".
