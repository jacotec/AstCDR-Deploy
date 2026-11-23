#!/usr/bin/env bash
# Creates the read-only MariaDB user AstCDR needs (SELECT on asteriskcdrdb.cdr/cel,
# plus a few name columns of the FreePBX database for the operator panel).
# Run on the FreePBX host as root (the system root user reaches MariaDB via socket):
#
#     sudo ./setup-db-user.sh
#
# Prompts for a password (or generates a safe one), creates the user idempotently,
# and offers to write SOURCE_DB_PASSWORD into .env for you.
set -euo pipefail

DB_USER="cdrjournal_ro"
DB_NAME="asteriskcdrdb"

echo "AstCDR — read-only database user setup"
echo

# --- 1) Password: type one, or press Enter for a safe random one --------------
read -rsp "Password for '$DB_USER' (Enter = auto-generate, recommended): " PW1; echo
if [ -z "$PW1" ]; then
  PW="$(openssl rand -hex 24)"
  echo "-> generated a random password."
else
  read -rsp "Repeat password: " PW2; echo
  [ "$PW1" = "$PW2" ] || { echo "Passwords do not match. Aborting."; exit 1; }
  PW="$PW1"
  case "$PW" in
    *'$'*) echo "WARNING: the password contains '\$' — Docker Compose mangles that in .env."
           echo "         An auto-generated password (just press Enter) avoids this." ;;
  esac
fi

# --- 2) Create/refresh user + grants (idempotent) -----------------------------
# Password goes via stdin SQL (not the process list); single quotes are escaped.
PW_SQL="${PW//\'/\'\'}"
if ! mysql <<SQL
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$PW_SQL';
ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$PW_SQL';
GRANT SELECT ON $DB_NAME.cdr TO '$DB_USER'@'localhost';
GRANT SELECT ON $DB_NAME.cel TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
SQL
then
  echo
  echo "ERROR: could not talk to MariaDB as root."
  echo "       Run this as root (sudo), or make sure 'mysql' connects with rights"
  echo "       to CREATE USER (on FreePBX, 'sudo mysql' normally just works)."
  exit 1
fi

echo
echo "OK: '$DB_USER'@'localhost' may now SELECT $DB_NAME.cdr and $DB_NAME.cel."

# --- 2b) Operator panel (licensed version): names from the FreePBX database ----
# Only single COLUMNS — these tables also hold secrets (passwords, conference PINs),
# which the user never gets. A table that does not exist (module not installed) is
# skipped; the panel then shows numbers instead of names there.
grant_cols() {   # table "col1, col2, …"
  if mysql -e "GRANT SELECT ($2) ON asterisk.$1 TO '$DB_USER'@'localhost'" 2>/dev/null; then
    echo "   + asterisk.$1 ($2)"
  else
    echo "   - asterisk.$1 skipped (table missing?)"
  fi
}
echo "Operator panel: read access to names in the FreePBX database (only these columns):"
grant_cols users "extension, name"
grant_cols queues_config "extension, descr"
grant_cols meetme "exten, description"
grant_cols parkplus "name, parkext, parkpos, numslots"
mysql -e "FLUSH PRIVILEGES" 2>/dev/null || true
echo

# --- 3) Offer to write it into .env -------------------------------------------
ENV_FILE="$(cd "$(dirname "$0")" && pwd)/.env"
SAFE=0
case "$PW" in *[!A-Za-z0-9]*) SAFE=0 ;; *) SAFE=1 ;; esac   # only auto-edit safe chars

if [ -f "$ENV_FILE" ] && [ "$SAFE" = "1" ]; then
  read -rp "Write SOURCE_DB_PASSWORD into .env now? [y/N] " ANS
  case "${ANS:-}" in
    y|Y)
      if grep -q '^SOURCE_DB_PASSWORD=' "$ENV_FILE"; then
        sed -i "s/^SOURCE_DB_PASSWORD=.*/SOURCE_DB_PASSWORD=$PW/" "$ENV_FILE"
      else
        printf '\nSOURCE_DB_PASSWORD=%s\n' "$PW" >> "$ENV_FILE"
      fi
      echo "-> wrote SOURCE_DB_PASSWORD to $ENV_FILE"
      ;;
    *) echo "Put this into .env:  SOURCE_DB_PASSWORD=$PW" ;;
  esac
else
  echo "Put this into .env:  SOURCE_DB_PASSWORD=$PW"
fi
