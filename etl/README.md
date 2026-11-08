# ETL-Datenbankverbindung

Imports vom Projektverzeichnis aus starten. Alle Imports verwenden
`etl/db_connection.R` statt der alten Verbindung unter `shiny_old`.
Benötigt werden die R-Pakete `DBI` und `RPostgres`.

Die Verbindung benötigt `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` und
`DB_PASSWORD_FILE`. Optional ist `PGSSLMODE` (Standard: `prefer`).
Das Passwort gehört ausschließlich in eine lesegeschützte Datei, nicht in
R-Code, `.env` oder `PGPASSWORD`. Die Funktion lädt keine `.env` automatisch.

Beispiel für die R-Konsole auf dem Docker-Host:

```r
Sys.setenv(
  PGHOST = "127.0.0.1",
  PGPORT = "5433",
  PGDATABASE = "klimahistorie",
  PGUSER = "climate_etl",
  DB_PASSWORD_FILE = normalizePath("secrets/postgres_etl_password", mustWork = TRUE)
)
source("etl/db_connection.R")
local({
  con <- db_connection()
  on.exit(DBI::dbDisconnect(con))
  DBI::dbGetQuery(con, "SELECT current_database(), current_user")
})
```

In einem ETL-Container im Datenbanknetz ist `PGHOST=postgres` und der Passwortpfad
zeigt auf das gemountete Secret; der interne Port bleibt `5432`.
Compose bindet PostgreSQL auf dem Host ausschließlich an `127.0.0.1:5433`.
Migration `003` legt `climate_etl` mit `SELECT`, `INSERT`, `UPDATE`
und Sequenznutzung an; Tabellenanlage und Löschen sind nicht erlaubt.
Standardrechte gelten für zukünftige Tabellen, die `postgres` im Schema `public` erstellt.
`climate_reader` bleibt ohne Import-Schreibrechte.

Das ETL-Passwort liegt in `secrets/postgres_etl_password` (Dateimodus `600`, nicht in Git).
Nach Migration `003` wird es mit `bash db/set-etl-password.sh` gesetzt. Bei einem
frischen Daten-Volume sind Migrationen und dieser Passwortschritt erneut nötig.
Zur Rotation die Secret-Datei sicher ersetzen, den PostgreSQL-Service neu erstellen,
und das Passwortskript erneut ausführen. Niemals Passwortwerte in Befehle schreiben.

Die Verbindungskonfiguration darf nicht ausgegeben werden, da sie interne Adressen
und Dateipfade enthält. Treiberfehler werden durch eine allgemeine Fehlermeldung ersetzt,
damit keine Zugangsdaten in Logs erscheinen.

## Tagesdaten im Rohformat

Zuerst Migration `004` mit `bash db/migrate.sh` anwenden. Anschließend kann eine
einzelne Station importiert werden:

```r
source("etl/db_connection.R")
source("etl/daily_data.R")
import_daily_data(station_ids = 1L)
```

Für kurze Testläufe begrenzt `n_stations` die Anzahl der Stationen:

```r
import_daily_data(n_stations = 5)
```

Standard ist `n_stations = NULL`: alle ausgewählten Stationen. Ohne explizite IDs
werden die ersten Stationen nach aufsteigender Stations-ID verwendet, keine Zufallsstichprobe.
Bei `station_ids` bleibt deren Reihenfolge erhalten; doppelte IDs werden nur einmal
gezählt. Ist das Limit größer als die Auswahl, werden alle verfügbaren Stationen importiert.
Fortschrittsmeldungen beziehen sich auf die begrenzte Auswahl und lassen sich mit
`progress = FALSE` abschalten.

### Aktuelle, historische oder beide Archive auswählen

Mit `period` lässt sich die Herkunft auswählen. Standard ist `"both"`, sodass
bisherige Aufrufe weiterhin historische und aktuelle Archive verarbeiten:

```r
source("etl/db_connection.R")
source("etl/daily_data.R")

# Regelmäßige Aktualisierung: nur die aktuellen DWD-Archive.
import_daily_data(period = "recent")

# Historischer Bestand: nur historische Archive.
import_daily_data(period = "historical")

# Vollständiger Import beider Archivarten (auch der Standard ohne period).
import_daily_data(period = "both")

# Begrenzter Testlauf für aktuelle Daten.
import_daily_data(period = "recent", n_stations = 5)
```

Diese Aufrufe sind Alternativen, keine notwendige Abfolge. Nicht ausgewählte
Archivarten werden weder geladen noch aus dem Cache gelesen. `"recent"` bedeutet
alle Zeilen der aktuellen DWD-Archive, nicht nur Tage seit dem letzten Import.
Die Stationsauswahl bleibt in allen Modi gleich; für stillgelegte Stationen
gegebenenfalls `station_ids` ausdrücklich angeben.

Die Auswahl löscht keine bereits gespeicherten Daten. **Auch ein rein historischer
Import aktualisiert vorhandene Zeilen mit gleichem Stations-/Datumsschlüssel**
und kann damit Werte aus einem früheren aktuellen Import überschreiben.
Der Vorrang aktueller Daten gilt beim Zusammenführen innerhalb eines
`period = "both"`-Laufs, nicht als dauerhafte Datenbankregel.

`source("etl/Import_climate_data.R")` startet den vollständigen Import für die bisherige
Stationsauswahl: Tages-Klimastationen mit verfügbaren Dateien und einem Enddatum
innerhalb der letzten zwei Jahre. Je Station werden alle verfügbaren historischen
und aktuellen Tageszeilen eingelesen, nicht nur die letzten zwei Jahre.
Stillgelegte Stationen außerhalb dieser Auswahl lassen sich explizit per
`station_ids` importieren.

Alle 19 Originalspalten bleiben erhalten, einschließlich Qualitätskennzeichen und
`eor`. `MESS_DATUM` bleibt Text im Format `YYYYMMDD`, `-999` bleibt als Fehlwertcode
stehen. Es gibt keine Umbenennung, keine berechneten Spalten und keine Ersetzung von
`QN_3`. Numerische Werte werden als Zahlen eingelesen, nicht als unveränderte Textbytes.
Stationsnamen können über die Metadatentabelle abgefragt werden.

Der Upsert verwendet `STATIONS_ID, MESS_DATUM`. Bei Überlappungen haben aktuelle
(`recent`) Zeilen Vorrang; vorhandene Werte werden aktualisiert.
Duplikate innerhalb derselben Herkunft und abweichende Produktspalten führen zum
Abbruch statt stillschweigendem Datenverlust. Jede Station wird in einer Transaktion
importiert; bereits abgeschlossene Stationen bleiben bei späteren Fehlern gespeichert.
Ein erneuter Lauf ist möglich. Archive bleiben im von Git ausgeschlossenen `DWDdata/`;
aktuelle Archive werden neu geladen, historische zwischengespeichert. Für einen
erneuten Abruf möglicherweise korrigierter historischer Daten ein neues `cache_dir`
verwenden. Es werden keine Cache-Dateien automatisch gelöscht.

Die Rohstruktur ist nicht kompatibel mit den alten Spaltennamen der Legacy-App
unter `shiny_old`. Dortige Abfragen benötigen später eine angepasste Sicht oder neue
Abfragen, insbesondere für Datumswerte und Fehlwertcodes.

Tests ohne Datenbankzugriff: `source("etl/tests/test-daily-data.R")`.
