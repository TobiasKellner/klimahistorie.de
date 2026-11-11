# Docker-Build für die Shiny-App neu aufsetzen

## Vereinbarter Umfang

Dockerfile vollständig neu aufbauen, `.dockerignore`, ein eigenständiges Produktions-Lockfile und Docker-Dokumentation ergänzen. `docker-compose.yml`, externe Nginx-/TLS-Konfiguration, ETL, `shiny_old` und das projektweite `renv.lock` bleiben unverändert. E-Mail-Versand bleibt pausiert.

## Ausgangslage

Die aktuelle App unter `shiny/` verwendet `shiny`, `bslib` und `htmltools` sowie deren transitive Abhängigkeiten. Sie benötigt noch keine Datenbank, Geobibliotheken oder persistenten Speicher. Das projektweite Lockfile enthält 107 Pakete und R 4.5.3; der bisherige Container basiert auf R 4.5.0 und enthält den alten, umfangreichen Shiny-/ETL-Stack. Eine `.dockerignore` fehlt. Compose erwartet Port 3838 und setzt `SHINY_PORT=3838`; die referenzierten Nginx-/Zertifikatsdateien sind nicht im Workspace vorhanden.

## Umsetzung

1. **Produktionsabhängigkeiten isolieren.** Ein separates Lockfile unter `docker/renv.lock` aus den vorhandenen Paketversionen erstellen: ausschließlich `shiny`, `bslib`, `htmltools`, ihre notwendigen Laufzeitabhängigkeiten und die gepinnte renv-Version. Die transitive Closure anhand der Paketmetadaten prüfen, nicht anhand einer geratenen Paketliste. Projekt-Lockfile und lokale R-Umgebung nicht verändern.

2. **Neues Multi-Stage-Dockerfile.** Eine verfügbare, fest versionierte R-4.5.3-Basis prüfen und für Builder und Runtime dieselbe Distribution verwenden. Im Builder nur notwendige Compiler/System-Developmentbibliotheken installieren und das Produktions-Lockfile mit gepinntem renv wiederherstellen. Die Paketbibliothek ohne externe renv-Cache-Symlinks in das Runtime-Image übernehmen. Im finalen Image nur R, notwendige Shared Libraries und App-Code behalten. Keine Testpakete, Browser, ETL-, DB- oder Geo-Werkzeuge und keine vollständige Tidyverse/Shiny-Server-Installation. Basisversion und Grenzen der Reproduzierbarkeit dokumentieren; verifizierbare Digests verwenden, wenn verfügbar.

3. **Sicherer und eindeutiger Start.** Festen Nicht-Root-Benutzer einrichten. Nur `shiny/app.R`, `shiny/R/` und aktive Assets aus `shiny/www/` kopieren; Tests und archivierte Styles nicht in das Produktionsimage aufnehmen. Ein kleines Startskript unter `docker/` bindet direkt per `shiny::runApp()` an `0.0.0.0`, verwendet `SHINY_PORT` (Standard 3838), validiert den Port und läuft als Hauptprozess in Exec-Form. Kein Projekt-.Rprofile und kein Paketdownload beim Containerstart. Logs nach stdout/stderr; HTTP-Healthcheck ohne Browser. Root-Dateisystem muss nicht beschreibbar sein, abgesehen vom R-Tempverzeichnis.

4. **Build-Kontext begrenzen.** `.dockerignore` als explizite Allowlist für erforderliche App-/Docker-Dateien gestalten. `.git`, `.posit`, lokale Paketbibliotheken, `shiny_old`, ETL, Logs, Konfigurationen und Zugangsdaten aus dem Build-Kontext ausschließen. Keine Secrets ins Image kopieren.

5. **Dokumentation aktualisieren.** In der Projekt-/App-Dokumentation Build- und Run-Befehle, Portkonfiguration, Nicht-Root-Betrieb, optionalen Read-only-Betrieb mit `/tmp`-tmpfs, Healthcheck und Pflege des Produktions-Lockfiles beschreiben. Compose bleibt kompatibel, wird aber nicht verändert. Auf fehlende lokale Nginx-/TLS-Dateien hinweisen; keine Zertifikate erzeugen oder vorhandene Infrastruktur unterstellen.

6. **Prüfen.** Bestehende R-Unit-/Modultests ausführen. Dockerfile/Änderungen statisch prüfen, Image bauen, einen eindeutig benannten kurzlebigen Testcontainer auf einem freien lokalen Port starten, HTTP-Antwort und Favicon abrufen, Healthcheck und Nicht-Root-UID verifizieren. Nach Möglichkeit Read-only-Start mit `/tmp`-tmpfs prüfen. Nur selbst erzeugte Testcontainer aufräumen; keine vorhandenen Dienste stoppen oder Images/Volumes löschen. Build- oder Netzwerkgrenzen transparent berichten. Keine Änderungen stagen oder committen.

## Abnahme

Das Image startet die aktuelle App auf Port 3838 ohne Secrets oder Laufzeit-Paketinstallation. Produktionsabhängigkeiten sind separat versioniert, der Prozess läuft ohne Root-Rechte und HTTP/Assets sind erreichbar. App-Tests bleiben grün. Compose und alte App bleiben unberührt; Docker-Anleitung entspricht dem neuen Betrieb.
