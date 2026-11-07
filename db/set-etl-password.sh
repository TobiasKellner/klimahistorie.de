#!/usr/bin/env bash
set -euo pipefail

db_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(dirname -- "$db_dir")"

# The secret stays inside the container environment, never in command arguments.
docker compose --project-directory "$project_dir" \
  -f "$project_dir/docker-compose.yml" exec -T postgres sh -c '
    set -eu
    ETL_DB_PASSWORD="$(cat /run/secrets/postgres_etl_password)"
    test -n "$ETL_DB_PASSWORD"
    export ETL_DB_PASSWORD
    exec psql -X -U postgres -d klimahistorie -v ON_ERROR_STOP=1
  ' <<'SQL'
\getenv etl_password ETL_DB_PASSWORD
SET password_encryption = 'scram-sha-256';
ALTER ROLE climate_etl PASSWORD :'etl_password';
SQL
