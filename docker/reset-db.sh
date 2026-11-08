#!/usr/bin/env bash
set -euo pipefail

if [[ "${CONFIRM:-}" != DELETE_KLIMAHISTORIE_DB ]]; then
  echo 'Abbruch: Dieser Reset löscht sämtliche Daten in der Compose-Datenbank.' >&2
  echo 'Expliziter Aufruf: make db-reset CONFIRM=DELETE_KLIMAHISTORIE_DB' >&2
  exit 1
fi

project_dir="$(dirname -- "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)")"
compose=(docker compose --project-directory "$project_dir" -f "$project_dir/docker-compose.yml")
container="$("${compose[@]}" ps -aq postgres)"
if [[ -z "$container" || "$container" == *$'\n'* ]]; then
  echo 'Abbruch: Kein eindeutiger PostgreSQL-Container gefunden; nichts gelöscht.' >&2
  exit 1
fi

volume="$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{if eq .Type "volume"}}{{.Name}}{{end}}{{end}}{{end}}' "$container")"
if [[ -z "$volume" ]]; then
  echo 'Abbruch: Kein benanntes PostgreSQL-Datenvolume gefunden; nichts gelöscht.' >&2
  exit 1
fi
project="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$container")"
volume_name="$(docker volume inspect -f '{{index .Labels "com.docker.compose.volume"}}' "$volume")"
volume_project="$(docker volume inspect -f '{{index .Labels "com.docker.compose.project"}}' "$volume")"
if [[ -z "$project" || "$project" == '<no value>' ||
      "$volume_name" != postgres_data || "$volume_project" != "$project" ]]; then
  echo 'Abbruch: Volume-Labels passen nicht zur Compose-Datenbank; nichts gelöscht.' >&2
  exit 1
fi

echo "Lösche PostgreSQL-Datenvolume: $volume"
"${compose[@]}" stop shiny-app postgres
"${compose[@]}" rm -f postgres
docker volume rm "$volume"
echo 'Reset abgeschlossen. Secrets bleiben erhalten. Neuaufbau mit make install.'
