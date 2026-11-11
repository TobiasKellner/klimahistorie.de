# Auf dem Deployment-Server aus der Projektwurzel aufrufen.
# Voraussetzungen: GNU Make, Bash, OpenSSL und Docker Compose v2 mit --wait.
# Dieses Makefile verwaltet nur PostgreSQL und Shiny, niemals den Host-Nginx.
SHELL := /bin/bash
# Bei Fehlern, unbekannten Shell-Variablen oder fehlgeschlagenen Pipelines abbrechen.
.SHELLFLAGS := -eu -o pipefail -c
# Ein Aufruf ohne Ziel zeigt Hilfe und verändert nichts.
.DEFAULT_GOAL := help
# Die Reset-Bestätigung an das Skript weitergeben, nicht als Shell-Code einsetzen.
export CONFIRM

# Ziele sind Aktionen; gleichnamige Dateien dürfen ihre Ausführung nicht verhindern.
.PHONY: help secrets db-up migrate etl-password install build deploy status logs db-reset

help:
	@printf '%s\n' \
	  'make install       DB-Secrets anlegen, PostgreSQL starten, migrieren, App deployen' \
	  'make deploy        App neu bauen und ersetzen (DB bleibt unverändert)' \
	  'make secrets       Nur fehlende lokale PostgreSQL-Secrets erzeugen' \
	  'make db-up         PostgreSQL starten und auf Bereitschaft warten' \
	  'make migrate       Ausstehende Migrationen anwenden' \
	  'make etl-password  ETL-Rollenpasswort aus dem gemounteten Secret setzen' \
	  'make build         Nur das App-Image bauen' \
	  'make status        Containerstatus anzeigen' \
	  'make logs          Letzte App- und DB-Logs anzeigen' \
	  'make db-reset CONFIRM=DELETE_KLIMAHISTORIE_DB' \
	  '                   Nur das PostgreSQL-Datenvolume unwiderruflich löschen'

# Nur fehlende Standarddateien erzeugen; vorhandene Passwörter bleiben erhalten.
# Externe Compose-Secret-Pfade müssen separat bereitgestellt werden.
# Neue Dateien ändern keine Rollenpasswörter einer bereits initialisierten DB.
secrets:
	bash docker/create-db-secrets.sh

# Auf den Healthcheck warten, bevor Migrationen oder App-Starts folgen.
# Es wird nur postgres gestartet, nicht der zusätzliche Compose-Nginx.
db-up:
	docker compose up -d --wait --wait-timeout 120 postgres

# Benötigt eine laufende DB. Unveränderte angewendete Migrationen werden übersprungen.
# Bereits angewendete SQL-Dateien nicht nachträglich ändern; neue Migration anlegen.
migrate:
	bash db/migrate.sh

# Erst nach migrate: Die Rolle climate_etl entsteht in Migration 003.
# Das Skript liest das Secret im Container, ohne das Passwort auszugeben.
etl-password:
	bash db/set-etl-password.sh

# Rekursive Aufrufe sichern die Reihenfolge auch bei make -j; Fehler stoppen den Ablauf.
# Keine automatische Löschung, Passwortrotation für Admin/App oder DWD-Datenimporte.
# Wiederholungen sind möglich, starten die App aber neu und setzen das ETL-Passwort.
install:
	$(MAKE) secrets
	$(MAKE) db-up
	$(MAKE) migrate
	$(MAKE) etl-password
	$(MAKE) deploy

# Nur das Image bauen; laufende Container bleiben bis zum Deployment unverändert.
# Docker nutzt den Build-Cache. Neue R-Pakete müssen im Runtime-Lockfile stehen.
build:
	docker compose build shiny-app

# build ist Voraussetzung; ein bloßer Container-Neustart übernimmt keinen neuen Code.
# --no-deps: PostgreSQL nicht neu erstellen; die DB muss bereits laufen.
# --force-recreate: App sicher ersetzen, auch wenn Compose keine Änderung erkennt.
# --wait: Healthcheck abwarten. Bestehende Shiny-Sitzungen werden unterbrochen.
deploy: build
	docker compose up -d --no-deps --force-recreate --wait --wait-timeout 120 shiny-app

# Auch gestoppte Container anzeigen; keine Änderungen am Deployment.
status:
	docker compose ps -a postgres shiny-app

# Begrenzte Ausgabe statt dauerhaftem Follow-Modus; Logs können interne Details enthalten.
logs:
	docker compose logs --tail=100 postgres shiny-app

# Gefährliche Aktion, niemals Abhängigkeit von install oder deploy!
# Nur mit CONFIRM=DELETE_KLIMAHISTORIE_DB: geprüftes postgres_data-Volume löschen.
# Secrets bleiben bestehen; danach make install und Datenimporte erneut ausführen.
db-reset:
	@bash docker/reset-db.sh
