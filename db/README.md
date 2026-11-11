# Datenbankmigrationen

Migrationen ändern das Schema; die Skripte unter `etl/` importieren anschließend
die Daten. Migrationen laufen als Administrator, nicht als `climate_reader`.

## Ausführen

PostgreSQL muss laufen. Vom Projektverzeichnis aus:

```bash
docker compose up -d postgres
bash db/migrate.sh
```

Der Runner verwendet `psql` im PostgreSQL-Container über dessen lokalen Socket.
Es werden keine Passwörter ausgelesen oder als Argumente übergeben. Ein weiterer
Datenbankport ist nicht nötig. Die Compose-Datei wird unabhängig vom aktuellen
Arbeitsverzeichnis gefunden.

Angewendete Migrationen stehen in `migration_admin.schema_migrations`, einschließlich
Dateiname, SHA-256-Prüfsumme und Zeitpunkt. Wiederholte Läufe überspringen unveränderte,
bereits angewendete Dateien. Veränderte angewendete Dateien führen zum Abbruch.
Eine Sitzungssperre verhindert parallele Ausführungen dieses Runners.

Jede Migration und ihr Verwaltungseintrag werden in derselben Transaktion ausgeführt.
Bei einem Fehler wird die laufende Migration zurückgerollt; zuvor erfolgreich
angewendete Migrationen bleiben bestehen. Nach Behebung des Fehlers erneut starten.

## Neue Migration

Dateinamen haben das Format `NNN_beschreibung.sql`, beispielsweise:

```text
001_create_stationstabelle.sql
002_expand_stationstabelle.sql
003_create_climate_etl.sql
004_create_tagesdaten.sql
005_create_current_air_temperature_stations.sql
```

Verwende eindeutige, aufsteigende Nummern. Bereits angewendete Dateien nicht ändern
oder umbenennen; Änderungen gehören in eine neue Migration. Angewendete Dateien
bleiben im Repository. Neue Dateien immer mit einer höheren Nummer ergänzen.

SQL-Dateien enthalten weder eigene `BEGIN`/`COMMIT`-Anweisungen noch psql-Kommandos
wie `\connect` oder `\quit`. Operationen, die nicht in einer Transaktion laufen dürfen
(etwa `CREATE INDEX CONCURRENTLY`), benötigen einen separat geplanten Ablauf.
`CREATE TABLE IF NOT EXISTS` sollte keine abweichenden bestehenden Strukturen verdecken.

## Bereits manuell angelegte Stationstabelle

Migration `002` erweitert die Stationstabelle auf alle 13 Rohspalten des rdwd-Indexes.
Der Primärschlüssel und der ETL-Upsert verwenden gemeinsam
`STATIONS_ID, res, var, per, von_datum, bis_datum, Abgabe`.
`Abgabe` wird benötigt, weil einzelne Zeilen sonst trotz gleicher Datumsbereiche
kollidieren. Der Import verwirft keine Rohzeilen und prüft den Schlüssel vor dem Schreiben.
Ein Import läuft in einer Transaktion. Bei geänderten Schlüsselwerten entstehen neue
Zeilen; frühere Einträge werden durch den Upsert nicht gelöscht.

Migration `002` verlangt eine leere Stationstabelle und bricht andernfalls ohne
Datenverlust ab: Den bisherigen sechs Spalten lassen sich die fehlenden Produkt- und
Zeitraumangaben nicht eindeutig zuordnen. Bereits vorhandene Daten müssen daher vorab
bewusst übernommen werden. Die alte Datenbankverbindung der ETL-Skripte muss außerdem
vor einem Import für die Ziel-Datenbank mit Schreibrechten konfiguriert sein.

Die bisherige `Create_Database.sql` ist jetzt Migration
`001_create_stationstabelle.sql`. Wenn sie schon manuell ausgeführt wurde, aber noch
kein Migrationseintrag existiert, bricht der Runner beim Anlegen der Tabelle ab.
In diesem Fall zuerst die bestehende Struktur prüfen und eine bewusste Übernahme in
die Migrationsverwaltung vornehmen. Nicht die Tabelle oder das Daten-Volume löschen.

## Status prüfen

Migration `005` erstellt die materialisierte View `public."AktuelleTemperaturstationen"`
mit einer Zeile pro Stations-ID einschließlich Name, Lage und ausgewählter
Produktmetadaten. Grundlage sind alle vorhandenen Temperaturangebote
(`hasfile = TRUE`): `air_temperature` mit `per IN ('now', 'recent')` oder
`res = 'daily', var = 'kl', per = 'recent'`. Historische Angebote allein reichen
nicht aus. Bei mehreren passenden Zeilen wird die mit dem neuesten End- und
Startdatum gewählt; weitere Sortierfelder lösen Gleichstände deterministisch auf.
Die View ist unabhängig von `Tagesdaten` und wird von der Shiny-Auswahl gelesen.

„Aktuell“ bezeichnet hier das Produktangebot laut importiertem Index, keinen
nachgewiesenen heutigen Messwert. Alte Rohzeilen bleiben beim bestehenden Upsert
erhalten; die View kann deshalb veraltete Angebote übernehmen. Ein aktueller
Stationsindex und künftig eine vollständige Synchronisation sind dafür relevant.

Die Migration befüllt die View sofort. `etl/Import_station_table.R` aktualisiert
sie anschließend bei jedem Import in derselben Transaktion über
`public.refresh_current_air_temperature_stations()`. Die eng begrenzte
`SECURITY DEFINER`-Funktion erlaubt dem ETL-Benutzer den Refresh ohne allgemeine
Owner-Rechte; der App-Leser erhält ausschließlich SELECT. Der normale Refresh
kann Leser kurz blockieren, hält aber Import und Stationsliste atomar konsistent.
Bereits offene Shiny-Sitzungen behalten ihre geladene Stationsliste.

Manueller Refresh als Administrator:

```bash
docker compose exec -T postgres psql -X -U postgres -d klimahistorie \
  -c 'REFRESH MATERIALIZED VIEW public."AktuelleTemperaturstationen";'
```

Der Integrationstest läuft in einem isolierten Schema und rollt alle Testobjekte zurück:

```bash
bash db/tests/test-current-stations.sh
```

Migration `004` erstellt `Tagesdaten` mit allen 19 Originalspalten der DWD-Tagesdateien
(`daily/kl`). Der Schlüssel ist `(STATIONS_ID, MESS_DATUM)`. Datumscodes bleiben
achtstelliger Text, Fehlwerte bleiben `-999`; SQL-Auswertungen müssen diese Codes
ausdrücklich berücksichtigen. Die Tabelle enthält keine berechneten Spalten.

```bash
docker compose exec postgres psql -X -U postgres -d klimahistorie \
  -c 'TABLE migration_admin.schema_migrations;'
```
