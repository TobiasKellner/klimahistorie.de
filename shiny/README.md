# Shiny

Modularer UI-Prototyp für Klimahistorie.de mit Shiny und bslib (Bootstrap 5).
Alle sechs Filtertabs laden dieselbe Stationsauswahl aus PostgreSQL. Der erste
Tab „Durchschnitte & Trends“ lädt außerdem Jahresmittel. „Tageswerte“ zeigt neun
Wetterkennzahlen für den gewählten Standort und Tag; fehlende Werte und der
DWD-Fehlwertcode `-999` werden als „Nicht verfügbar“ dargestellt. „Stationsübersicht“ zeigt
eine interaktive Karte aller aktiven Temperaturstationen. „Jahresvergleich“ vergleicht
Tagesverläufe ausgewählter Jahre mit allen verfügbaren Jahren als Hintergrund;
optional erscheint das Mittel je Kalendertag (einschließlich 29. Februar).
„Tageshistorie“ zeigt die Messwerte eines Kalendertags über alle verfügbaren Jahre,
mit optionalem Mittelwert und absteigender Sortierung nach Messwert.
„Klimarekorde“ zeigt neun Maxima oder Minima aus den verfügbaren Tagesmessungen;
bei Gleichstand wird das früheste Datum angezeigt. „Tage über & unter“ zählt
jährlich gültige Tageswerte auf oder über bzw. auf oder unter einer wählbaren
Schwelle für Temperatur, Schnee, Sonne oder Niederschlag. Die Schwellenbereiche
und Standardwerte entsprechen der alten App; das laufende Jahr ist standardmäßig
ausgeschlossen. Die Aggregation erfolgt in PostgreSQL (`R/thresholds_data.R`),
SQL-NULL und `-999` zählen nicht mit. Jahre ohne gültige Werte werden ausgelassen,
gültige Jahre ohne Schwellenüberschreitung erhalten den Wert null. Unvollständige
Jahre bleiben wie in der alten App enthalten; die Zahl gültiger Tageswerte wird
im Tooltip angezeigt und ein Hinweis erläutert die eingeschränkte Vergleichbarkeit.

## Start

Aus der Projektwurzel:

```r
shiny::runApp("shiny")
```

Aus dem App-Verzeichnis: `shiny::runApp(".")`. In Positron kann `app.R` über
„Run App“ gestartet werden. Das projektweite renv verwaltet die Umgebung;
Laufzeitpakete sind `shiny`, `bslib`, `htmltools`, `ggplot2`, `plotly` und `leaflet`; bei konfigurierter Datenbank
zusätzlich `DBI`, `RPostgres` und `pool`. Tests benötigen zusätzlich `testthat`,
`withr`, `htmltools` und für Browser-Tests `shinytest2` sowie Chrome/Chromium.
Testpakete sind noch nicht automatisch im projektweiten Lockfile festgeschrieben.

## Architektur

| Datei | Verantwortung |
|---|---|
| `app.R` | R-Dateien isoliert laden und App zusammenstellen |
| `R/app_ui.R` | Seitenrahmen und Ansichten zusammensetzen |
| `R/app_server.R` | Navigation und Module orchestrieren |
| `R/app_config.R` | Stabile Tab-IDs, Labels, Icons und Auswahlwerte |
| `R/app_theme.R` | Bootstrap-Theme |
| `R/db_pool.R` | Datenbankkonfiguration, gemeinsamer Pool und Abfragehelfer |
| `R/ui_components.R` | Logo, Navigation und gemeinsame Filter-Card |
| `R/mod_*.R` | UI und Server eines fachlichen Bereichs |
| `R/view_*.R` | Statische Ansichten ohne Serverlogik |
| `www/custom.css` | Aktive App-Styles |
| `www/legacy/` | Archivierte, ausdrücklich nicht geladene Alt-Styles/-Handler |

Die sechs Filtermodule verwenden `NS()` und `moduleServer()`. Lokale IDs heißen
`station`, `variable`, `month`, `date`, `years`, `record_type` und `filters`, je
nach Ansicht. Im Browser entstehen daraus IDs wie `trends-variable`.
Navigation nutzt stabile englische Werte statt deutscher Beschriftungen.

Jeder Modul-Server liefert eine `reactive()` mit einer benannten Liste seiner
Filterwerte. Werte können vor Browser-Initialisierung `NULL` sein. Die Liste
bildet Eingaben unverändert ab; insbesondere werden Jahre noch nicht geparst
und es erfolgt noch keine fachliche Validierung. Beide Sidebar-Typen verwenden
ausschließlich die nativen bslib-Schalter, keine eigenen Click-Handler.

## Tests

Der erste Tab verwendet alle vier Variablen aus der alten App: `TMK` (Temperatur),
`SHK_TAG` (Schnee), `SDK` (Sonne) und `RSK` (Niederschlag). Stationsauswahl und
Jahresmittel werden über `R/trends_data.R` in PostgreSQL abgefragt. Die Stationsliste
liest die materialisierte View `public."AktuelleTemperaturstationen"` (Migration 005).
Sie enthält alle Temperaturangebote des importierten DWD-Stationsindexes:
`air_temperature` mit `now` oder `recent` sowie `daily/kl` mit `recent`, jeweils
mit `hasfile = TRUE`. Sie ist unabhängig vom lokalen Tagesdatenimport
und wird einmal pro Browsersitzung für alle Tabs geladen. Eine eindeutige,
deterministisch ausgewählte Metadatenzeile pro Stations-ID verhindert Duplikate.
Der Stationsindex muss regelmäßig importiert werden, damit das aktuelle DWD-Angebot
abgebildet wird. Der Metadatenimport aktualisiert die View in derselben Transaktion.
Wählbare Stationen können noch ohne lokal importierte Tageswerte sein.
Die Monatsauswahl reicht von gesamtem Jahr bis Dezember; das laufende Jahr und die
Trendlinie sind standardmäßig ausgeschaltet.

`-999` und SQL-NULL werden ausgeschlossen; gültige Nullen und negative Temperaturen bleiben.
Mittelwerte werden auf eine Dezimalstelle gerundet. Schnee/Temperatur sind Mittelwerte,
Sonne (Stunden/Tag) und Regen (mm/Tag) ebenfalls Tagesmittel, keine Summen.
Nur vollständige Kalenderjahre bzw. ausgewählte Kalendermonate werden angezeigt:
Für jeden Tag muss ein gültiger Wert der gewählten Variable vorliegen.
Schaltjahre werden berücksichtigt; unvollständige oder noch nicht abgeschlossene
Zeiträume erhalten keinen Balken. Im laufenden Jahr können daher nur bereits
abgeschlossene, vollständige Monate erscheinen. Die zuschaltbare
Trendlinie wird wie bisher ungewichtet auf gerundeten Jahresmitteln berechnet,
ab zwei gültigen Jahren, ohne Konfidenzband oder Signifikanztest.

Der Plot ist interaktiv; die Filter-/Plot-Card bietet Vollbild. Die alte Wert-Farbskala
wird nicht übernommen. Datenbankfehler und fehlende Daten werden neutral angezeigt.
Docker-Laufzeitabhängigkeiten wurden im separaten Lockfile ergänzt; das Image muss
für diese Änderungen neu gebaut werden.

Aus der Projektwurzel:

```r
source("shiny/tests/testthat.R")
source("shiny/tests/browser.R")
```

Aus dem App-Verzeichnis entsprechend `source("tests/testthat.R")` und
`source("tests/browser.R")`.

Unit-Tests prüfen Konfiguration, Namespacing und den App-Einstieg. Modul-Tests
prüfen reaktive Filterzustände, unabhängige Modulinstanzen und Navigation.
Browser-Tests starten eine isolierte App, bedienen die echten Tab- und
Sidebar-Schalter, prüfen Sichtbarkeit/Breite und erhaltene Filterwerte sowie
eine schmale Bildschirmbreite. Es werden keine Screenshot-Baselines benötigt.
Auf Linux ohne Desktop kann `CHROMOTE_CHROME` auf den Chromium-Pfad gesetzt
werden; in einer isolierten Containerumgebung können zusätzliche Chrome-Flags
erforderlich sein. Diese Umgebungseinstellungen gehören nicht in die App.

Der Browser-Test wurde in dieser Linux-Containerumgebung mit folgender
temporärer Konfiguration erfolgreich ausgeführt. `--no-sandbox` nur in einer
bereits isolierten, vertrauenswürdigen Testumgebung verwenden:

```r
withr::with_envvar(
  c(
    CHROMOTE_CHROME = "/usr/bin/chromium",
    CHROMOTE_CHROME_ARGS = "--no-sandbox --disable-dev-shm-usage --disable-gpu"
  ),
  withr::with_options(
    list(chromote.timeout = 60),
    source("shiny/tests/browser.R")
  )
)
```

## Weiterentwicklung

Die Stationsübersicht liest ID, Name, Bundesland, Höhe und Koordinaten aus
`AktuelleTemperaturstationen`, unabhängig von vorhandenen Tageswerten.
Ungültige oder fehlende Koordinaten werden ausgeschlossen. OpenStreetMap liefert
die Hintergrundkarte; Marker zeigen Stationsinformationen per Tooltip und Popup.
Der Kartenausschnitt umfasst alle verfügbaren Stationen und die Karte ist
vollbildfähig. Anders als in der alten App verändert ein Marker-Klick keine
Standortauswahl in den anderen Tabs. `leaflet` ist im Projekt-Lockfile vorhanden;
vor einem Docker-Deployment muss es einschließlich Systemabhängigkeiten zusätzlich
im separaten Docker-Laufzeit-Lockfile und Image ergänzt werden.

Die App erzeugt beim tatsächlichen Start einen gemeinsamen Verbindungspool pro
R-Prozess, nicht pro Browsersitzung. Er wird ausschließlich beim Stoppen der App
geschlossen. Der Server erhält ihn als Argument `db_pool`; innerhalb einer Sitzung
steht derselbe Pool auch unter `session$userData$db_pool` bereit. Künftige Module
sollten ihn ausdrücklich als Argument erhalten.

Ohne `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` und `DB_PASSWORD_FILE` startet
die App lokal ohne Datenbank. Sobald einzelne Werte gesetzt sind, müssen alle
vorliegen; eine ungültige Konfiguration oder fehlgeschlagene Anmeldung bricht den
Start mit einer neutralen Fehlermeldung ab. Das Passwort wird aus genau einer
nichtleeren Zeile der Secret-Datei gelesen, nicht aus `PGPASSWORD`.

Beim lokalen Start über Positrons „Run App“ werden die Umgebungsvariablen aus
Docker Compose nicht übernommen. Die App liest daher beim Start eine optionale
Datei `shiny/.Renviron` ein. Diese ist von Git ausgeschlossen und wird nicht
ins Docker-Image kopiert. Für die lokale Compose-Datenbank enthält sie:

```text
PGHOST=127.0.0.1
PGPORT=5432
PGDATABASE=klimahistorie
PGUSER=climate_reader
DB_PASSWORD_FILE=/absoluter/pfad/zum/projekt/secrets/postgres_app_password
```

Den absoluten Dateipfad an die lokale Umgebung anpassen. Die Konfiguration wird
auch nach einem Neustart der Shiny-Konsole erneut eingelesen; sie überschreibt
gegebenenfalls die entsprechenden Sitzungsvariablen. Das Passwort bleibt in
der Secret-Datei.

`database_query(db_pool, sql, params)` führt DBI-Abfragen aus. Nutzereingaben
immer als Parameter übergeben (PostgreSQL-Platzhalter `$1`, `$2`, …), nicht in SQL
einfügen. Der Pool hat höchstens fünf Verbindungen, fünf Sekunden Verbindungs-
und 15 Sekunden Abfrage-Timeout. Jede neue Verbindung aktiviert Read-only-
Transaktionen; zusätzliche Sicherheit liefern die Datenbankrechte des Lesebenutzers.
Bestehende Verbindungen werden bei jeder Entnahme geprüft und bei Bedarf ersetzt.
Bei einer weiterhin unerreichbaren Datenbank schlagen Abfragen fehl; es gibt keine
unbegrenzten Wiederholungen und keine automatische Wiederholung fachlicher Abfragen.

`PGSSLMODE` steuert libpq-TLS (Standard `prefer`, passend zur lokalen Compose-DB).
Das garantiert keine Verschlüsselung. Für entfernte Datenbanken `verify-full`
und die passende CA über `PGSSLROOTCERT` bereitstellen.

Datenzugriff und Klimaberechnungen als reine oder explizit parametrisierte
Funktionen unter `R/` ergänzen und separat mit Unit-Tests prüfen. Benötigte
Daten/Provider explizit an Modul-Server übergeben statt globale Datenobjekte
oder Datenbankverbindungen vorauszusetzen. Module verarbeiten dann ihre
Filterzustände und geben die benötigten Ergebnisse zurück. Neue fachliche
Regeln einschließlich fehlender Werte zuerst definieren, dann implementieren.

Die bisherige App liegt als Orientierungshilfe unter `shiny_old/`.

## Kontaktformular: IONOS SMTP

Der Versand nutzt `curl::send_mail()` mit festem Absender und Empfänger.
Die Besucheradresse wird ausschließlich als `Reply-To` gesetzt. Betreff und
Nachricht werden als UTF-8-MIME kodiert. Es gibt keine Marketing-Kontaktliste,
kein Tracking und keine Speicherung der Nachricht durch die App. IONOS und
das empfangende beziehungsweise weiterleitende Postfach verarbeiten die E-Mail
dennoch; diese Verarbeitung muss in der Datenschutzerklärung berücksichtigt werden.

Ohne ausdrückliche Aktivierung bleibt der Versand deaktiviert. Für die lokale
App können folgende Werte in der nicht versionierten `shiny/.Renviron` stehen:

```text
CONTACT_SMTP_ENABLED=true
CONTACT_SMTP_USERNAME=kontakt@example.org
CONTACT_MAIL_TO=kontakt@example.org
CONTACT_SMTP_PORT=465
CONTACT_SMTP_PASSWORD_FILE=/absoluter/pfad/zum/secret/contact_smtp_password
```

| Variable | Bedeutung / Standard |
| --- | --- |
| `CONTACT_SMTP_ENABLED` | Nur `true` aktiviert den Versand; Standard `false`. |
| `CONTACT_SMTP_USERNAME` | Vollständige Adresse des IONOS Mail-Basic-/Business-Postfachs; zugleich Absender. |
| `CONTACT_MAIL_TO` | Feste Empfängeradresse; Standard ist `CONTACT_SMTP_USERNAME`. Eine Weiterleitung kann dort eingerichtet sein. |
| `CONTACT_SMTP_PORT` | `465` mit TLS ab Verbindungsbeginn; alternativ `587` mit zwingendem STARTTLS. |
| `CONTACT_SMTP_PASSWORD_FILE` | Pfad zu einer lesbaren Datei mit genau einer nichtleeren Zeile: dem Postfach-Passwort, nicht dem IONOS-Kundenpasswort. |

Der Server ist fest `smtp.ionos.de`. TLS-Zertifikate werden geprüft; ein
unverschlüsselter Fallback ist ausgeschlossen. Das Passwort nicht in Git,
Chat, Docker-Image oder `.env` ablegen. Die Secret-Datei außerhalb des
Repositories oder unter dem ignorierten Verzeichnis `secrets/` erstellen und
nur für den App-Benutzer lesbar machen. Konfigurationsobjekte nicht ausgeben.

Ein gültiger Versandversuch ist pro Shiny-Sitzung höchstens alle 60 Sekunden
möglich, auch nach Fehlern oder erneutem Öffnen des Dialogs. Dies ist kein
globaler Spamschutz: Neue Sitzungen umgehen diese Begrenzung. Bei öffentlichem
Betrieb zusätzlich passende verbindungs-/sitzungsübergreifende Begrenzungen
am Reverse-Proxy erwägen. Es werden keine Besucher-IP-Adressen dafür gespeichert.
SMTP blockiert den R-Prozess synchron für maximal zehn Sekunden (Verbindungsaufbau
maximal fünf Sekunden). Für höhere Last wäre ein Hintergrunddienst nötig.

Die Erfolgsmeldung bestätigt nur die Übergabe an den Mailserver. Nach einem
Timeout kann die E-Mail bereits angenommen worden sein; es gibt bewusst keine
automatische Wiederholung, um doppelte Nachrichten zu vermeiden. Technische
Versandfehler, Zugangsdaten und Nachrichtentexte werden nicht protokolliert oder
an Besucher ausgegeben. Nach Konfigurationsänderungen die App neu starten.
Die Unit-Tests verwenden ausschließlich einen simulierten SMTP-Transport.
Eine reale Zustellprüfung erst nach Einrichtung der Zugangsdaten durchführen.

Die Docker-Konfiguration verwendet `shiny/` und bindet damit diese modulare App ein.
Das Produktionsimage startet die App ohne zusätzlichen Shiny Server und verwendet
ein separates Laufzeit-Lockfile. Build- und Startbefehle sowie Hinweise zu
Healthcheck und Reverse Proxy stehen in der [Docker-Dokumentation](../docker/README.md).
