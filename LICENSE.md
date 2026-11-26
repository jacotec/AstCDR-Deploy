# License & activation

AstCDR is **donationware**. It runs fully without a license, but with limits. A
license removes those limits. There is **no expiry** and **no host binding** — the
license is a small signed file you drop in place. It includes **updates for a period of
time** (see [Scope of a license](#scope-of-a-license)); the version you run keeps working
forever.

## Support AstCDR ☕

AstCDR is built and maintained by one developer in his own time. If it's useful to
you, a small donation keeps it maintained and new features coming:

For a donation of **€50 or more**, I'll issue you a license that removes the free
version's limits (the 100-row and 30-day caps) and unlocks the licensed features —
operator panel, voicemail, recordings, phone books and codec capture. **Updates for one
year** are included; every additional **€25** adds another year (€75 = two years, €100 =
three years, …).

If you'd like one, please write **"I'd like a license"** in your donation message, along
with the **name** and **email address** the license should be made out to. Please also
tick **"Make this message private"** so your details don't become public. I'll then send
you the license file by email.

**Extending updates later:** donate €25 per further year with the same name and email in
the message — you get a new license file whose update period continues from the end of
your current one.

<a href="https://buymeacoffee.com/jacotec" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy me a coffee" height="48"></a>

→ [buymeacoffee.com/jacotec](https://buymeacoffee.com/jacotec) — thank you! 🙏

## Free vs. licensed

| | Free (no license) | Licensed |
|---|---|---|
| Journal rows shown | **100 most recent** (no further pages) | unlimited |
| History fetched by the engine | **last 30 days** (older cache entries are actively pruned) | full history |
| Codec & media capture (`ami` block: codecs, transcoding, SRTP/TLS, voice quality) | **not available** — the `ami` block is ignored, AstCDR behaves as if it weren't configured | available |
| Operator panel (incl. phone control and conference rooms) | **not available** | available |
| Voicemail and call recordings (panel and journal) | **not available** | available |
| Phone books (LDAP, CardDAV, Contact Manager, own book, Superfecta) | **not available** | available |
| Footer | *Unregistered Version* | *Licensed for &lt;name&gt;, &lt;email&gt; — updates until &lt;date&gt;* (older licenses without an update period: *— Main Version N.x*) |

Everything else — filters, columns, sorting, details, statistics, costs, export, OIDC,
roles, geo — is identical in both modes. Rights for licensed functions can be granted in the
free version too, but have no effect until a license is in place.

## Activating a license

1. Obtain your `astcdr.lic` file.
2. Put it into the **`license/`** folder, next to `docker-compose.yml`:
   ```
   /opt/astcdr/license/astcdr.lic
   ```
3. **That's it.** AstCDR picks it up **automatically within a few seconds — no
   restart needed.** The footer switches to *Licensed for …*. A configured codec
   capture (`ami` block) and the operator panel start on their own within a minute.
4. If this instance ran as the **free version** before, rebuild the cache once so
   the full history is imported (the free version only kept the last 30 days):
   ```bash
   ./reset-cache.sh
   ```

The compose file mounts `./license` permanently, so there is **no compose edit**
and no container change involved — an empty folder simply means the free version.

## Scope of a license

- **Updates:** a license covers every release **built until a date** — the footer shows
  *updates until &lt;date&gt;*. That includes new major versions: if 3.0 comes out within
  your update period, your license covers it. The date is checked against the build date
  stored in the image, never against your server's clock: the version you run keeps
  working **forever**, even long after that date. Only a release built **after** it does
  not accept the license.
- **Licenses without an update period** (issued before 2.0 went public) are tied to their
  **major version** instead: a `2` license covers all **2.x** releases, but not 3.0. The
  footer shows *Main Version N.x* for them.
- **If you update past your update period**, that release runs like the free version —
  but it deletes **nothing** (the history beyond 30 days and the codec data stay), and the
  footer says *updates until &lt;date&gt; — this build is from &lt;date&gt;, a newer
  license is needed*. Either get a new license (everything is back at once, no rebuild),
  or go back to the release you had: pin it in `.env`, e.g.
  `CDRJ_IMAGE=ghcr.io/jacotec/astcdr:2.3.1`, then `docker compose up -d` (see
  [UPGRADE.md](UPGRADE.md#pin-a-fixed-version-instead-of-latest)).
- No expiry, no per-host activation — you may use the same file on your instance(s)
  as covered by your donation.

## Notes

- Keep the `license/` folder out of version control (the bundle's `.gitignore`
  already excludes `license/*.lic`).
- Removing the file returns the instance to the free limits on the next license
  check (and the next prune cycle will trim history back to 30 days).

Problems (e.g. footer stays "Unregistered"): [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
