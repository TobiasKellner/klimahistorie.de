#!/usr/bin/env bash
set -euo pipefail

project_dir="$(dirname -- "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)")"
secret_dir="$project_dir/secrets"
mkdir -p -- "$secret_dir"
chmod 700 "$secret_dir"
umask 077

for name in postgres_admin_password postgres_app_password postgres_etl_password; do
  path="$secret_dir/$name"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    # Noclobber also protects against another setup process creating the file.
    (set -C; openssl rand -hex 32 > "$path")
    if [[ "$name" == postgres_etl_password ]]; then
      chmod 600 "$path"
    else
      chmod 444 "$path"
    fi
  fi
  # Check format without showing the password or changing existing permissions.
  if [[ ! -f "$path" || ! -r "$path" ]] ||
    ! awk 'length($0) == 0 { invalid = 1 } END { exit (NR != 1 || invalid) }' "$path"; then
    echo "Ungültige Passwortdatei: $path (genau eine nichtleere, lesbare Zeile erforderlich)." >&2
    exit 1
  fi
done

echo 'Lokale PostgreSQL-Secrets vorhanden; bestehende Inhalte wurden nicht verändert.'
echo 'Externe Secret-Pfade in Compose müssen separat bereitgestellt werden.'
