#!/usr/bin/env bash
set -euo pipefail

db_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
project_dir="$(dirname -- "$db_dir")"

{
  cat <<'SQL'
BEGIN;
CREATE SCHEMA climate_station_view_test;
GRANT USAGE ON SCHEMA climate_station_view_test TO climate_reader, climate_etl;
CREATE TABLE climate_station_view_test."Stationstabelle"
    (LIKE public."Stationstabelle" INCLUDING ALL);
INSERT INTO climate_station_view_test."Stationstabelle"
    ("STATIONS_ID", "Stationsname", "von_datum", "bis_datum", "Abgabe", res, var, per, hasfile)
VALUES
    (1, 'Now', '2020-01-01', '2026-07-01', 'Frei', '10_minutes', 'air_temperature', 'now', TRUE),
    (1, 'Older', '2020-01-01', '2025-07-01', 'Frei', 'hourly', 'air_temperature', 'recent', TRUE),
    (2, 'Hourly', '2020-01-01', '2026-06-30', 'Frei', 'hourly', 'air_temperature', 'recent', TRUE),
    (3, 'Daily', '2020-01-01', '2026-06-30', 'Frei', 'daily', 'kl', 'recent', TRUE),
    (4, 'Historical', '2020-01-01', '2026-06-30', 'Frei', 'hourly', 'air_temperature', 'historical', TRUE),
    (5, 'No file', '2020-01-01', '2026-06-30', 'Frei', 'hourly', 'air_temperature', 'recent', FALSE),
    (6, 'Unknown file', '2020-01-01', '2026-06-30', 'Frei', 'hourly', 'air_temperature', 'recent', NULL),
    (7, 'Rain', '2020-01-01', '2026-06-30', 'Frei', 'daily', 'more_precip', 'recent', TRUE),
    (8, 'Annual', '2020-01-01', '2026-06-30', 'Frei', 'annual', 'kl', 'recent', TRUE);
SQL
  # Execute the actual migration against isolated fixture tables.
  sed 's/public\./climate_station_view_test./g' \
    "$db_dir/migrations/005_create_current_air_temperature_stations.sql"
  cat <<'SQL'
DO $$
BEGIN
    IF (SELECT array_agg("STATIONS_ID" ORDER BY "STATIONS_ID")
        FROM climate_station_view_test."AktuelleTemperaturstationen") <> ARRAY[1, 2, 3] THEN
        RAISE EXCEPTION 'Incorrect station inclusion or deduplication';
    END IF;
    IF (SELECT "Stationsname" FROM climate_station_view_test."AktuelleTemperaturstationen"
        WHERE "STATIONS_ID" = 1) <> 'Now' THEN
        RAISE EXCEPTION 'Incorrect metadata selection';
    END IF;
    IF has_function_privilege('climate_reader',
        'climate_station_view_test.refresh_current_air_temperature_stations()', 'EXECUTE') THEN
        RAISE EXCEPTION 'Reader must not be allowed to refresh';
    END IF;
END;
$$;
SET LOCAL ROLE climate_reader;
SELECT * FROM climate_station_view_test."AktuelleTemperaturstationen" ORDER BY "STATIONS_ID";
RESET ROLE;
INSERT INTO climate_station_view_test."Stationstabelle"
    ("STATIONS_ID", "Stationsname", "von_datum", "bis_datum", "Abgabe", res, var, per, hasfile)
VALUES (9, 'New', '2020-01-01', '2026-07-01', 'Frei', 'subdaily', 'air_temperature', 'recent', TRUE);
SET LOCAL ROLE climate_etl;
SELECT climate_station_view_test.refresh_current_air_temperature_stations();
DO $$
BEGIN
    IF (SELECT count(*) FROM climate_station_view_test."AktuelleTemperaturstationen") <> 4 THEN
        RAISE EXCEPTION 'ETL refresh failed';
    END IF;
END;
$$;
RESET ROLE;
ROLLBACK;
SQL
} | docker compose --project-directory "$project_dir" \
  -f "$project_dir/docker-compose.yml" exec -T postgres \
  psql -X -U postgres -d klimahistorie -v ON_ERROR_STOP=1
