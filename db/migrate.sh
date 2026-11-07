#!/usr/bin/env bash
set -euo pipefail

db_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(dirname -- "$db_dir")"
shopt -s nullglob
export LC_ALL=C
migrations=("$db_dir"/migrations/*.sql)

if ((${#migrations[@]} == 0)); then
  echo 'Keine Migrationen gefunden.' >&2
  exit 1
fi

declare -A versions=()
for migration in "${migrations[@]}"; do
  name="${migration##*/}"
  if [[ ! "$name" =~ ^([0-9]{3})_[a-z0-9_]+\.sql$ ]]; then
    echo "Ungültiger Migrationsname: $name" >&2
    exit 1
  fi
  version="${BASH_REMATCH[1]}"
  if [[ -n "${versions[$version]:-}" ]]; then
    echo "Doppelte Migrationsnummer: $version" >&2
    exit 1
  fi
  versions[$version]=1
done

generate_sql() {
  cat <<'SQL'
\set ON_ERROR_STOP on
SELECT pg_advisory_lock(71029, 18061);
BEGIN;
CREATE SCHEMA IF NOT EXISTS migration_admin;
REVOKE ALL ON SCHEMA migration_admin FROM PUBLIC;
CREATE TABLE IF NOT EXISTS migration_admin.schema_migrations (
    version text PRIMARY KEY,
    filename text NOT NULL,
    checksum text NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now()
);
COMMIT;
SQL

  for migration in "${migrations[@]}"; do
    name="${migration##*/}"
    version="${name%%_*}"
    checksum="$(sha256sum -- "$migration")"
    checksum="${checksum%% *}"
    cat <<SQL
SELECT EXISTS (
    SELECT 1 FROM migration_admin.schema_migrations WHERE version = '$version'
) AS applied,
EXISTS (
    SELECT 1 FROM migration_admin.schema_migrations
    WHERE version = '$version' AND filename = '$name' AND checksum = '$checksum'
) AS matches \gset migration_
\if :migration_applied
  \if :migration_matches
    \echo Bereits angewendet: $name
  \else
    DO \$\$ BEGIN RAISE EXCEPTION 'Angewendete Migration wurde verändert: $name'; END \$\$;
  \endif
\else
  \echo Anwenden: $name
  BEGIN;
SQL
    cat -- "$migration"
    cat <<SQL

INSERT INTO migration_admin.schema_migrations (version, filename, checksum)
VALUES ('$version', '$name', '$checksum');
COMMIT;
\endif
SQL
  done
  echo 'SELECT pg_advisory_unlock(71029, 18061);'
}

# One psql session keeps the advisory lock across all migrations.
generate_sql | docker compose --project-directory "$project_dir" \
  -f "$project_dir/docker-compose.yml" exec -T postgres \
  psql -X -U postgres -d klimahistorie -v ON_ERROR_STOP=1
