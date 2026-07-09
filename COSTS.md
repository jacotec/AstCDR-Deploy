# Call costs (outbound)

AstCDR can estimate the cost of your **outbound** calls from a tariff file you
provide, and show it as journal columns, in the call detail, and as a **Cost** KPI.
It's an estimate based on the call's billed seconds, the dialed number and the
trunk — no external lookups.

- Only **outbound** calls get costs. Inbound, internal and system events stay empty.
- A call over a trunk that isn't in the tariff file stays empty too (perfectly fine
  — e.g. a free internal site-to-site trunk).

## Enabling it

The compose file mounts a **`costs.yaml`** (next to your `config.yaml`) into the
containers, so **the file must exist** — just like `config.yaml`. Create it:

```bash
cp costs.example.yaml costs.yaml   # then edit it to add your tariffs
# ...or, if you DON'T use call costs, just create an empty file:
#   (Linux/macOS)  : > costs.yaml
```

An **empty** `costs.yaml` simply means cost calculation is off.

**Applying changes.** When you edit `costs.yaml` in place, the ingest picks up the
new tariffs **automatically** (within one poll cycle) — no restart needed. As an
admin you can validate the file right away under gear icon → **Check config**.

Existing calls keep their old cost until a **cache rebuild** (costs are computed as
calls are read in): as an admin, gear icon → **Rebuild cache**, or `./reset-cache.sh`
on the host. So the usual workflow after a tariff change is: edit `costs.yaml` →
**Rebuild cache**.

> If you only just **created** `costs.yaml` (it didn't exist when the stack came up),
> the compose bind-mount needs to attach it once — run `docker compose up -d`. The
> same applies if your editor saves atomically (new inode) and the container still
> shows the old content: `docker compose up -d --force-recreate`. See
> [UPGRADE.md](UPGRADE.md).

## The tariff file

One section per **trunk** (matched case-insensitively against the trunk name in your
CDRs), each with `settings` and `zones`:

```yaml
easybell:
  settings:
    currency: "€"
    bill_interval: 60          # 1 = per-second billing, 60 = per-minute
    country_code: "+49"        # your country in E.164
    local_area: "2275"         # your area code, without the leading 0
    national_prefix: "0"
    intl_prefix: "00"
  zones:
    national:
      name: National
      cost: 0.015              # price per minute
      freemin: 1000            # optional: free minutes per calendar month
    mobile:
      name: Mobile
      prefixes: ["+49151.", "+4916.", "+4917."]
      cost: 0.19
      freemin: 200
    swiss:
      name: Switzerland
      prefixes: ["+41."]
      cost: 0.09
    emergency:
      name: Emergency
      prefixes: ["110", "112"]
      cost: 0
      no_normalize: true
    international:             # fallback for everything else
      name: International
      cost: 0.29
```

> **Always quote prefixes and digit values** (`"+49."`, `"0"`, `"00"`). Unquoted,
> YAML turns them into numbers and drops the leading `+` — the admin panel flags
> this as an error.

### `settings`

| Key | Meaning |
|-----|---------|
| `currency` | Display symbol (e.g. `€`). It does not affect the math. |
| `bill_interval` | Billing increment in seconds: `1` = per-second, `60` = per-minute (your provider's rounding). |
| `country_code` | Your own country in E.164 (`+49`). Acts as the implicit prefix of the `national` zone. |
| `local_area` | Your own area code, without the leading `0`. Used when a local number is dialed without any prefix. |
| `national_prefix` | National dialing prefix (usually `0`). |
| `intl_prefix` | International dialing prefix (usually `00`). |

### Zones

`national` and `international` are **required**. `international` is the catch-all
fallback. You can add any number of extra zones (mobile, per country, groups, …).

| Key | Required | Meaning |
|-----|----------|---------|
| `name` | yes | Display name shown in the Zone column. |
| `prefixes` | yes* | List of E.164 prefixes. **Not** allowed on `national`/`international`. |
| `cost` | yes | Price per minute (up to 4 decimals). |
| `freemin` | no | Free minutes per **calendar month** for this zone. |
| `no_normalize` | no | `true` → match against the **raw dialed** number (for emergency/service numbers). |

*Extra zones need at least one prefix; `national`/`international` must have none.

## Create Tariff Data with AI

Nobody should hand-type a hundred country rates in 2026. Your provider publishes a
price list (PDF, web page, spreadsheet) — hand it to an AI assistant (Claude,
ChatGPT, Gemini) **together with the prompt below** and let it produce the tariff
block for you. Fill in the parts in ⟨angle brackets⟩, attach or paste your provider's
price list, and paste the AI's output under the right trunk in your `costs.yaml`.

Run it **once per trunk**. When it's done: paste the block into `costs.yaml` →
gear → **Check config** (validates the structure) → **Rebuild cache**.

> The prompt is self-contained — it carries the full format spec, so it works in a
> fresh chat with any capable AI. Still: **review the result before you trust it.**
> An AI can misread a table. Spot-check a handful of zones (especially your
> highest-volume countries) against the original price list.

Copy everything inside the box:

````text
You are helping me build a tariff file for AstCDR, a phone call-journal tool.
Produce a single YAML block that describes the calling zones and per-minute prices
for ONE telephone trunk, based on the price list I provide.

WHAT I GIVE YOU
- Trunk name (use it verbatim as the top-level YAML key): ⟨e.g. easybell⟩
- My country and its E.164 code:                          ⟨e.g. Germany, +49⟩
- My local area code, without the leading 0:              ⟨e.g. 2275⟩
- Billing increment in seconds (1 = per second, 60 = per minute): ⟨e.g. 60⟩
- Currency symbol:                                        ⟨e.g. €⟩
- Prices are net or gross? If net, ADD this VAT and output GROSS prices:
                                                          ⟨e.g. 19% VAT / or "already gross"⟩
- Free minutes per calendar month, if any:               ⟨e.g. National 1000, Mobile 200 / or "none"⟩
- Price list:                                             ⟨attach the file / paste the table / links⟩

OUTPUT FORMAT — copy these keys exactly:

```yaml
⟨trunk-name⟩:
  settings:
    currency: "€"
    bill_interval: 60
    country_code: "+49"      # my country in E.164
    local_area: "2275"       # my area code, no leading 0
    national_prefix: "0"
    intl_prefix: "00"
  zones:
    national:                # REQUIRED, no prefixes — my own country
      name: National
      cost: 0.0150           # price per minute
      freemin: 1000          # optional
    mobile:
      name: Mobile
      prefixes: ["+49151.", "+49160.", "+49170."]
      cost: 0.1900
      freemin: 200
    switzerland:
      name: Switzerland
      prefixes: ["+41."]
      cost: 0.0900
    international:            # REQUIRED, no prefixes — catch-all fallback
      name: International
      cost: 0.2900
```

RULES
1. Output ONLY the YAML block — no prose, no explanation, no surrounding code fence.
2. `national` and `international` are REQUIRED and must have NO `prefixes`.
   `national` = my own country; `international` = the catch-all for everything else.
3. Every OTHER zone MUST have a `prefixes` list of E.164 prefixes, each a QUOTED
   string, e.g. "+41." for Switzerland. Look up every country's dialing code
   yourself — do not ask me for well-known dial codes.
4. Quote every prefix and every digit string ("+49.", "0", "00"). Unquoted, YAML
   turns "+49" into a number and drops the "+", which breaks the file.
5. In a prefix, "." means "any digits follow" and "X" means "exactly one digit".
   The LONGEST matching prefix wins, so make mobile ranges specific enough that they
   never collide with that country's landline zone, and never let two zones share
   the same prefix.
6. `cost` is the price per minute, up to 4 decimals. `freemin` is optional.
7. If a country lists BOTH a landline and a mobile price, use the LANDLINE price
   only (unless I tell you otherwise).
8. If prices are net, convert to gross with the VAT I gave you and round each gross
   price to 4 decimals.
9. Do NOT invent or guess prices. If a price is missing, ambiguous, or unreadable,
   DO NOT hallucinate — list your open questions and ask me before finalizing.

Here is the price list:
⟨paste / attach / link your provider's price list here⟩
````

## How a call is matched to a zone

1. **`no_normalize` zones first**, against the number exactly as dialed (so `110`
   stays emergency and isn't turned into a normal number).
2. Otherwise the dialed number is **normalized to E.164** using your `settings`
   (a bare local number becomes `country_code + local_area + number`; `0…` →
   national; `00…` → international; `+…` is taken as-is).
3. The zone with the **longest matching prefix** wins. `national` matches your
   `country_code`, `international` matches everything as the last resort. In a
   prefix, `.` means "anything from here" and `X` means "one digit".

If two zones are equally specific, the admin panel shows a warning and the first
one in the file is used.

## How the cost is calculated

1. The call's billed seconds are rounded **up** to the next `bill_interval`.
2. `price = cost-per-minute × billed-seconds ÷ 60`.
3. The result is rounded **up to the next whole cent**.

Example at €0.19/min for a 10-second call: with per-minute billing it's **€0.19**;
with per-second billing it's `0.19 × 10 ÷ 60 = €0.0317` → **€0.04**.

### Free minutes

If a zone has `freemin`, calls in that zone consume the monthly quota (in the
order they **end**); only the part beyond the quota is charged. The columns then
show:

- **Cost** — the gross price, ignoring free minutes.
- **Real cost** — what you actually pay, with free minutes applied.
- **Quota** — the free minutes left for that zone this month, as `(h:)mm:ss` (the
  same format as call duration; hours are shown only from one hour up).

## What you see

- Four optional, sortable columns: **Cost**, **Real cost**, **Zone**, **Quota**.
  Show/hide them like any other column.
- A **Cost** KPI card summing the *real* cost of the currently filtered calls.
- The same values in the expanded call detail.

Money is formatted per your interface language (e.g. `0,04 €` in German, `€0.04`
in English).

## Checking your tariff file

Open **Settings** (gear, admin) → **Costs / tariffs**. It lists the trunks that
loaded successfully and any errors or warnings. An error disables costs for that
**whole trunk** (so a typo never silently mis-bills) while other trunks keep
working.
