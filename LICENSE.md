# License & activation

AstCDR is **donationware**. It runs fully without a license, but with limits. A
license removes those limits. There is **no expiry** and **no host binding** — the
license is a small signed file you drop in place.

## Support AstCDR ☕

AstCDR is built and maintained by one developer in his own time. If it's useful to
you, a small donation keeps it maintained and new features coming:

<a href="https://buymeacoffee.com/jacotec" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy me a coffee" height="48"></a>

→ [buymeacoffee.com/jacotec](https://buymeacoffee.com/jacotec) — thank you! 🙏

## Free vs. licensed

| | Free (no license) | Licensed |
|---|---|---|
| Journal rows shown | **100 most recent** (no further pages) | unlimited |
| History fetched by the engine | **last 30 days** (older cache entries are actively pruned) | full history |
| Footer | *Unregistered Version* | *Licensed for &lt;name&gt;, &lt;email&gt; — Main Version N.x* |

Everything else — filters, columns, sorting, details, OIDC, geo — is identical in
both modes.

## Activating a license

1. Obtain your `astcdr.lic` file.
2. Put it into the **`license/`** folder, next to `docker-compose.yml`:
   ```
   /opt/astcdr/license/astcdr.lic
   ```
3. **That's it.** AstCDR picks it up **automatically within a few seconds — no
   restart needed.** The footer switches to *Licensed for …*.
4. If this instance ran as the **free version** before, rebuild the cache once so
   the full history is imported (the free version only kept the last 30 days):
   ```bash
   ./reset-cache.sh
   ```

The compose file mounts `./license` permanently, so there is **no compose edit**
and no container change involved — an empty folder simply means the free version.

## Scope of a license

- A license is tied to the **major version**: a `1` license covers **all 1.x**
  releases.
- No expiry, no per-host activation — you may use the same file on your instance(s)
  as covered by your donation.

## Notes

- Keep the `license/` folder out of version control (the bundle's `.gitignore`
  already excludes `license/*.lic`).
- Removing the file returns the instance to the free limits on the next license
  check (and the next prune cycle will trim history back to 30 days).

Problems (e.g. footer stays "Unregistered"): [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
