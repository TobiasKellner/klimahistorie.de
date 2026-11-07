# Docker-Betrieb

Für das Deployment auf AlmaLinux mit dem bereits installierten **Host-Nginx**
gilt die ausführliche [Deployment- und Nginx-Anleitung](DEPLOYMENT-NGINX.md).
In dieser Variante nur `docker compose up -d postgres shiny-app` verwenden;
der zusätzliche Compose-Nginx würde mit dem vorhandenen Proxy kollidieren.

Das Produktionsimage enthält die aktuelle App unter `shiny/` und startet sie
direkt mit `shiny::runApp()`. Ein zusätzlicher Shiny Server ist nicht erforderlich.
Der Prozess läuft mit UID/GID `10001:10001`; App-Dateien und Paketbibliothek
sind nur lesbar. Ausgaben gehen an die Containerlogs.

## Bauen und starten

Aus der Projektwurzel:

```bash
docker build -t klimahistorie:local .
docker run --rm --name klimahistorie-local \
  -p 127.0.0.1:3838:3838 klimahistorie:local
```

Die App ist unter http://127.0.0.1:3838 erreichbar. Die Bindung an localhost
ist für lokale Tests gedacht, nicht als öffentliche Freigabe.

Ein anderer Port im Container wird über `SHINY_PORT` eingestellt:

```bash
docker run --rm -e SHINY_PORT=8080 \
  -p 127.0.0.1:3838:8080 klimahistorie:local
```

Erlaubt sind ganze Portnummern von 1024 bis 65535. Standard ist 3838.

Der Shiny-Prototyp selbst benötigt keine persistenten Volumes; PostgreSQL in
Compose verwendet dagegen das dauerhafte Volume `postgres_data`. Optional kann Shiny
mit schreibgeschütztem Root-Dateisystem und einem temporären R-Verzeichnis laufen:

```bash
docker run --rm --read-only \
  --tmpfs /tmp:rw,nosuid,nodev,size=256m,mode=1777 \
  --cap-drop ALL --security-opt no-new-privileges:true \
  -p 127.0.0.1:3838:3838 klimahistorie:local
```

Der Healthcheck ruft alle 30 Sekunden die lokale HTTP-Startseite ab und prüft
auf den App-Namen; HTTP-Fehler führen zum Fehlschlag.
Er prüft nicht sämtliche reaktiven Funktionen oder
WebSocket-Verbindungen. Status und Logs lassen sich wie folgt anzeigen:

```bash
docker inspect --format '{{.State.Health.Status}}' klimahistorie-local
docker logs klimahistorie-local
```

## Abhängigkeiten und Wartung

Die R-4.5.3-Basis ist auf einen Multiarch-Digest festgelegt. Builder und Runtime
verwenden dasselbe Basisimage. Zusätzliche Buildbibliotheken werden nur im
Builder installiert; die Runtime erhält libuv, libpq, CA-Zertifikate sowie die
für Leaflet-Abhängigkeiten benötigten Geodaten-, SSL- und PNG-Bibliotheken.
Die Rocker-R-Basis selbst enthält bereits einige System-/Buildwerkzeuge;
dies ist kein distroless Image.

`docker/renv.lock` enthält `shiny`, `bslib`, `htmltools`, `renv`, `DBI`, `RPostgres`,
`pool`, `ggplot2`, `plotly`, `lubridate`, `leaflet`, `shinycssloaders` und deren
Laufzeitabhängigkeiten. Die Versionen
stammen aus dem projektweiten Lockfile. `renv` wird beim Build in Version 1.2.4
installiert; beim Start werden keine Pakete heruntergeladen.
Der renv-Cache ist beim Build deaktiviert, damit die kopierte Bibliothek keine
Symlinks auf einen außerhalb des Images liegenden Cache enthält.
Der Sass-Dateicache ist beim Start deaktiviert, damit das schreibgeschützte
Home-Verzeichnis nicht als Cache verwendet wird. `/tmp` muss für R beschreibbar sein.

Nach bewusstem Aktualisieren des Projekt-Lockfiles aus der Projektwurzel in R:

```r
source("docker/update-lock.R")
```

Bei neuen direkten App-Abhängigkeiten die Startliste in diesem Skript ergänzen.
Bei einem R-/renv-Upgrade außerdem Basisimage/Digest und die Bootstrap-Version
in `docker/restore.R` anpassen. Danach das Image neu bauen und testen.
Das Skript verändert weder das Projekt-Lockfile noch die lokale Paketbibliothek.

R-Paketversionen und Basisimage sind festgelegt; Ubuntu-Sicherheitsupdates aus
APT und die Verfügbarkeit historischer R-Pakete bleiben externe Abhängigkeiten.
Builds sind daher nicht vollständig bitweise reproduzierbar.
Die Lockdatei übernimmt Paketversionen, enthält jedoch keine Prüfsummen der
Quellarchive; auch der renv-Bootstrap setzt Vertrauen in das HTTPS-Repository voraus.
Der Build benötigt
Netzwerkzugriff auf Docker Hub, Ubuntu-Paketquellen und das im Lockfile
konfigurierte R-Repository. APT-Fehler brechen den Build ab.

Die `.dockerignore` verwendet eine Allowlist. Nur erforderliche Startskripte,
Lockfile, R-App-Code und aktive CSS-/JS-/PNG-/JPG-Assets gelangen in den Build-Kontext.
Neue Assettypen müssen dort ausdrücklich ergänzt werden. Tests, alte App,
archivierte Styles, ETL, lokale Konfigurationen und Secrets sind ausgeschlossen.

## Compose und Produktion

`docker-compose.yml` enthält Shiny, PostgreSQL 17 und Nginx. PostgreSQL ist im
`database_network` intern auf Port 5432 erreichbar; für hostseitige Imports wird
zusätzlich ausschließlich `127.0.0.1:5433` veröffentlicht. Eine bestehende
PostgreSQL-Installation auf Host-Port 5432 bleibt damit unverändert.
Shiny verbindet dieses Netz mit dem Proxy-Netz; Nginx selbst hat keinen Zugang
zum Datenbanknetz. Der direkte Shiny-Port 3838 ist nur an localhost gebunden.
Der konfigurierte Nginx benötigt externe Konfiguration und Zertifikate
unter `nginx/`; diese Dateien liegen derzeit nicht im Workspace vor.
Für einen unabhängigen App-Test genügt der oben beschriebene `docker run`.

### PostgreSQL vorbereiten und starten

Vor dem ersten Start drei unterschiedliche Passwortdateien anlegen, beispielsweise
auf dem Deployment-Server aus der Projektwurzel:

```bash
mkdir -p secrets
chmod 700 secrets
openssl rand -hex 32 > secrets/postgres_admin_password
openssl rand -hex 32 > secrets/postgres_app_password
openssl rand -hex 32 > secrets/postgres_etl_password
chmod 444 secrets/postgres_admin_password secrets/postgres_app_password
chmod 600 secrets/postgres_etl_password
docker compose config --quiet
docker compose up -d postgres
bash db/migrate.sh
bash db/set-etl-password.sh
docker compose up -d --build shiny-app
```

Dieses Beispiel gilt nur für eine Erstinstallation; vorhandene Passwortdateien
nicht überschreiben. Die ausführliche Anleitung zeigt eine Variante, die nur
fehlende Dateien erzeugt.

Die Dateien sind aus Git und dem Image ausgeschlossen. Alternativ können ihre
Pfade über `.env` gemäß `.env.example` auf Dateien außerhalb des Repositories
zeigen. Passwörter niemals in `.env` eintragen oder im Chat teilen.
Lokale Compose-Secrets sind schreibgeschützte Dateimounts, kein verschlüsselter
Secret-Speicher. Das Host-Verzeichnis bleibt privat (700); die gemounteten Dateien
müssen für die unterschiedlichen Container-UIDs lesbar sein. Bei anderen
Deployment-Plattformen deren Secret-Management verwenden.

Shiny wartet beim Start auf den PostgreSQL-Healthcheck. Dieser prüft die
Serverbereitschaft, nicht die Anwendungsauthentifizierung. Die App bekommt nur
das Passwort für `climate_reader`, nicht das Adminpasswort. Verbindungsparameter:

| Parameter | Wert |
|---|---|
| `PGHOST` | `postgres` |
| `PGPORT` | `5432` |
| `PGDATABASE` | `klimahistorie` |
| `PGUSER` | `climate_reader` |
| `DB_PASSWORD_FILE` | `/run/secrets/postgres_app_password` |

Die R-App baut beim Start einen gemeinsamen `pool` mit `RPostgres` auf und liest
das Lesebenutzer-Passwort aus der Secret-Datei. Fehlende Teilkonfiguration oder
fehlgeschlagene Anmeldung bricht den Start ab; ohne sämtliche DB-Einstellungen
ist ein lokaler Start ohne Datenbank möglich. Der Pool wird beim App-Stop geschlossen,
nicht beim Ende einzelner Sitzungen. Er prüft Verbindungen bei jeder Entnahme und
ersetzt ungültige Verbindungen. Die Ansichten benötigen die Tabellen und View aus
den Migrationen sowie anschließend über ETL importierte Stations- und Tagesdaten.
Es wird kein passwortloser Zugriff eingerichtet. Die Host-Anmeldung verwendet
SCRAM-SHA-256; das interne Docker-Netz allein ist keine TLS-Verschlüsselung.
Für hostübergreifende oder strengere Sicherheitsanforderungen zusätzlich TLS
mit Zertifikatsprüfung konfigurieren.

Beim erstmaligen Initialisieren eines leeren Volumes legt das Init-Skript den
Lesenutzer an. Er kann vorhandene Tabellen im Schema `public` lesen und erhält
Leserechte auf künftige Tabellen, die `postgres` dort erstellt. Bei anderen
Tabellenbesitzern oder Schemas die Grants und Default Privileges gezielt ergänzen.
Der ETL-Schreibnutzer und die fachlichen Tabellen werden durch die anschließend
auszuführenden Migrationen angelegt, nicht durch das PostgreSQL-Init-Skript selbst.

Das Init-Skript läuft nicht erneut auf bestehenden Datenvolumes. Das Austauschen
einer Passwortdatei ändert deshalb kein bestehendes Datenbankpasswort; Rotation
erfordert zusätzlich eine kontrollierte Rollenänderung in PostgreSQL.
Das Volume bleibt beim Neuerstellen des Containers und bei `docker compose down`
erhalten. **Nicht `docker compose down -v` verwenden**, wenn die Daten erhalten
bleiben sollen. Regelmäßige externe Backups und Wiederherstellungstests sind
vor einem produktiven Betrieb erforderlich; ein Volume ist kein Backup.
PostgreSQL-Major-Upgrades benötigen eine geplante Migration, nicht bloß einen
neuen Image-Tag. Auch bei gepinntem Digest Sicherheitsupdates bewusst einspielen.

Ein öffentlicher Betrieb benötigt einen HTTPS-Reverse-Proxy mit
WebSocket-Unterstützung und passenden Timeouts. Bei mehreren App-Instanzen
muss das Routing Shiny-Sitzungen berücksichtigen. Der direkte Start verwendet
einen R-Prozess pro Container; rechenintensive Aufgaben können alle Sitzungen
dieses Prozesses blockieren. Lastverteilung und Hintergrundaufgaben sind nicht
Teil dieses Docker-Umbaus. E-Mail-Versand bleibt deaktiviert.

## Stand der Prüfung

Die 85 vorhandenen App-Prüfungen bestehen nach dem Umbau. Das Basisimage und
sein Digest wurden über Docker Hub geprüft. Der vollständige Image-Build war
in der Entwicklungsumgebung wegen Timeouts zu den Ubuntu-Paketquellen nicht
abschließbar. Containerstart, HTTP-/Favicon-Abruf, Healthcheck und Read-only-Betrieb
sind deshalb noch nicht praktisch verifiziert und müssen nach einem erfolgreichen
Build geprüft werden.

Die Compose-Konfiguration und das PostgreSQL-Init-Skript wurden geprüft. In einem
isolierten Testcontainer mit temporären Daten funktionierten Initialisierung,
Passwortanmeldung und SELECT als `climate_reader`; INSERT wurde erwartungsgemäß
abgewiesen. Dieser Test hat keine produktive Datenbank oder persistenten Volumes
angelegt. Zusätzlich wurde der echte R-Verbindungspool mit parametrisiertem SELECT,
Read-only-Einstellungen, abgewiesenem INSERT und Wiederverbindung nach Abbruch
geprüft. Die automatisierten App-Tests wurden um Konfiguration und Pool-Lebenszyklus
ergänzt. Der vollständige Compose-Stack ist weiterhin nicht praktisch geprüft.
