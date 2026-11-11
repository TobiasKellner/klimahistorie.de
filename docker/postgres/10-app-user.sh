#!/usr/bin/env bash
set -euo pipefail

# Read via psql environment, never interpolate a password into SQL or arguments.
export APP_DB_PASSWORD
APP_DB_PASSWORD="$(cat /run/secrets/postgres_app_password)"
if [ -z "$APP_DB_PASSWORD" ]; then
  echo 'The application database password must not be empty.' >&2
  exit 1
fi
psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --set ON_ERROR_STOP=1 <<'SQL'
\getenv app_password APP_DB_PASSWORD
CREATE ROLE climate_reader LOGIN PASSWORD :'app_password'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
REVOKE CONNECT, TEMPORARY ON DATABASE klimahistorie FROM PUBLIC;
GRANT CONNECT ON DATABASE klimahistorie TO climate_reader;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO climate_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO climate_reader;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT SELECT ON TABLES TO climate_reader;
SQL
unset APP_DB_PASSWORD
