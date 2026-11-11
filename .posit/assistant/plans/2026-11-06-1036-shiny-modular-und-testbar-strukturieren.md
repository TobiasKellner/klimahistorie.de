# Shiny modular und testbar strukturieren

## Ziel und Grenzen

Die bestehende App wird zu einer übersichtlichen, modularen Shiny-Anwendung mit automatisierten Tests aufgebaut. Das aktuelle Layout, alle acht Ansichten, Beschriftungen, Icons, Filter, Logo-Beschnitt, Farben und eingebauten Sidebar-Schalter bleiben erhalten. Es werden keine Datenanbindung, Klimaberechnungen oder neuen fachlichen Funktionen erfunden. Änderungen beschränken sich auf `shiny`; die andere App unter `shiny_old`, Docker-Konfiguration und projektweite renv-Konfiguration bleiben unverändert.

Ein schlanker App-Aufbau ohne zusätzliches golem-/rhino-Framework oder Paketumbau reicht für diesen Entwicklungsstand aus.

## Ausgangslage

`shiny/app.R` enthält UI, Navigation, Theme und Server in einer Datei. Die sechs Filteransichten haben keine fachliche Serverlogik; Stationsübersicht und About sind statische Platzhalter. Es gibt keine Shiny-Module oder Tests. Shiny 1.14.0 und bslib 0.12.0 sind im Projekt-Lockfile enthalten. Ein altes AdminLTE-JavaScript wird absichtlich nicht mehr geladen, weil es die bslib-Sidebar-Initialisierung störte.

## Zielstruktur

```text
shiny/
  app.R                         # schlanker Einstieg und Laden der R-Dateien
  R/
    app_ui.R                    # Seitenrahmen und Zusammensetzen der Ansichten
    app_server.R                # Navigation und Modul-Orchestrierung
    app_config.R                # stabile Tab-IDs, Labels, Icons, Variablenauswahl
    app_theme.R                 # Bootstrap-Theme
    ui_components.R             # gemeinsamer Card-/Sidebar-Aufbau und Logo
    mod_trends.R                # UI und Server für Durchschnitte & Trends
    mod_daily_values.R          # UI und Server für Tageswerte
    mod_year_comparison.R       # UI und Server für Jahresvergleich
    mod_daily_history.R         # UI und Server für Tageshistorie
    mod_records.R               # UI und Server für Klimarekorde
    mod_thresholds.R            # UI und Server für Schwellenwerte
    view_stations.R             # statische Stationsansicht
    view_about.R                # statische About-Ansicht
  www/
    custom.css                  # nur aktive App-Styles
    legacy/                     # alte CSS-/JS-Dateien reversibel archivieren
    ...                         # Bilddateien unverändert
  tests/
    testthat.R                  # R-Test-Einstieg ohne Paketstruktur
    testthat/
      helper-app.R              # Funktionen isoliert laden, nicht die App starten
      test-config.R
      test-ui.R
      test-modules.R
      test-navigation.R
    browser/
      ...                       # separat ausführbare shinytest2-Regressionstests
  README.md                     # Architektur, Start und Testbefehle
```

## Umsetzung

1. **Rahmen und Konfiguration trennen.** UI-/Server-Funktionen erstellen und `app.R` auf einen deterministischen Lade-/Startpunkt reduzieren. Einmaliges Laden in eine App-Umgebung statt unnötiger globaler Seiteneffekte. Dateipfade sowohl für `shiny::runApp("shiny")` vom Projektwurzelverzeichnis als auch für Start aus dem App-Verzeichnis berücksichtigen. Maschinenlesbare Tab-Werte von den deutschen Labels trennen, damit Labeländerungen nicht die Navigation brechen.

2. **Sechs echte Shiny-Module einführen.** Je Filteransicht `mod_*_ui(id)` mit `NS()` und `mod_*_server(id)` mit `moduleServer()` anlegen. Alle lokalen Input- und Sidebar-IDs namespacen. Die Server geben einen dokumentierten reaktiven Filterzustand zurück, ohne Berechnungen oder Validierungsentscheidungen hinzuzuerfinden. Die Module werden im App-Server aufgerufen; Stationsübersicht/About bleiben einfache UI-Funktionen, solange sie keine Serverlogik benötigen.

3. **Gemeinsame UI-Bausteine gezielt extrahieren.** Wiederkehrende Card mit Card-Header, linker grauer, zunächst offener und einklappbarer Filter-Sidebar und rechter Inhaltsfläche in einen einfachen Builder überführen. Kein datengetriebenes Universalmodul oder unnötiges Vererbungsmodell. Logo und Navigation ebenfalls klar abgrenzen. Keine zusätzlichen Filter-Buttons.

4. **Styles ordnen.** Aktive Styles in `www/custom.css` bündeln; Theme in `app_theme.R` belassen. Alte AdminLTE-/Flip-/Map-Styles und das ungenutzte JavaScript reversibel nach `www/legacy/` verschieben und nicht laden. Die bislang aktive globale Bildabrundung bei der Extraktion für das Logo gezielt erhalten. Kein neues JavaScript für das Einklappen: bslib bleibt allein zuständig. Weißer Navigationshintergrund, graue Filterflächen, schwarze Tab-Schrift, Hover und Primary-Navbar bleiben unverändert.

5. **Unit- und Modul-Testbasis hinzufügen.** `testthat`-Tests für eindeutige/stabile Tab-IDs, vollständige Icon-Zuordnung, Default-Auswahl und UI-Namespacing. Mit `testServer()` die sechs Modulzustände und ihre Unabhängigkeit testen (Standort, Variable, Datum, Jahre, Rekordtyp je nach Modul). Die Navigationslogik mit gültigen Tab-Werten prüfen. Keine Tests für noch nicht vorhandene Klimaberechnungen; keine falschen Aussagen über Browser-Verhalten aus Mock-Session-Tests.

6. **Browser-Regressionstests hinzufügen.** Separat ausführbare `shinytest2`-Tests gegen die laufende App für alle acht Tab-Wechsel, native Pfeile der Navigations- und Filter-Sidebars, Ein- und Ausklappen, tatsächliche Sichtbarkeit, erhaltene Filterwerte und einen schmalen Viewport. Auf App-Bereitschaft/Animationen warten statt beliebiger langer Pausen. UI-Tests nicht nur auf HTML-Klassen beschränken. Screenshot-Vergleiche zunächst optional halten, damit Schrift-/Browserunterschiede keine unnötig fragilen Tests erzeugen.

7. **Dokumentieren und verifizieren.** Start- und Testbefehle, Dateiverantwortlichkeiten, Namespacing, Modul-Rückgaben und Erweiterungsweg für künftige reine Berechnungsfunktionen in einer kurzen App-README beschreiben. R-Tests ausführen, App starten und Browser-Tests durchführen. Fehlende Testpakete über Positron-Paketverwaltung prüfen/installieren; keine automatische Veränderung von `renv.lock`, kein Upgrade bestehender Laufzeitpakete. Wenn Browserwerkzeuge nicht ausführbar sind, Einschränkung ausdrücklich berichten statt Browserfunktion als geprüft auszugeben.

## Abnahmekriterien

- Die App lässt sich weiterhin aus dem Projekt mit `shiny::runApp("shiny")` starten.
- Layout und vorhandene Filterfunktionalität bleiben erhalten; beide Sidebar-Typen reagieren ausschließlich auf ihre nativen Schalter.
- `app.R` enthält keine vollständigen Tab-Layouts und keine Modul-Geschäftslogik mehr.
- Die sechs Filteransichten sind isoliert mit `testServer()` testbar und nutzen korrekt namespacete IDs.
- Konfiguration und wiederkehrende UI-Strukturen werden nicht mehrfach gepflegt.
- Unit-/Modul-Tests laufen erfolgreich; Browser-Prüfungen zeigen Tab-Wechsel und tatsächliches Ein-/Ausklappen.
- Alte Assets sind nicht gelöscht, alte JavaScript-Handler werden nicht eingebunden.
- Kein Refactoring der anderen App und keine neue fachliche Funktionalität.
