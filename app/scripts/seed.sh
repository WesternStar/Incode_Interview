#!/usr/bin/env bash
# Loads the Chinook schema + data into the target Postgres database.
# Usage: DATABASE_URL=postgres://user:pass@host:port/dbname ./scripts/seed.sh
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL must be set, e.g. postgres://user:pass@host:5432/appdb" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_FILE="$SCRIPT_DIR/../../Chinook_PostgreSql.sql"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$SEED_FILE"
