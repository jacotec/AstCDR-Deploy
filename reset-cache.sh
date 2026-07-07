#!/usr/bin/env bash
# Clears ONLY the cached call data (calls/segments/parties + high-water mark)
# and thereby triggers a fresh backfill. Users & prefs are preserved.
#
# Usage (in the stack directory, e.g. /opt/astcdr):
#     ./reset-cache.sh
#
# Do NOT use "docker compose down -v" for a cache refresh —
# that would delete the whole Postgres volume (including users/prefs).
set -euo pipefail
echo "Clearing the call cache (users/prefs are kept) ..."
docker compose exec -T cdrj-ingest python -m app.ingest.reset
echo "Done. The ingest worker will rebuild the cache within the next few seconds."
echo "Progress: docker compose logs -f cdrj-ingest"
