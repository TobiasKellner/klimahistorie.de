# Dokumentation

Diese Seite bündelt die technische Projektdokumentation.

## Einstieg

- App-Start und Architektur: [shiny/README.md](../shiny/README.md)
- ETL und Datenimporte: [etl/README.md](../etl/README.md)
- Docker-Betrieb: [docker/README.md](../docker/README.md)
- Deployment mit Host-Nginx (AlmaLinux): [docker/DEPLOYMENT-NGINX.md](../docker/DEPLOYMENT-NGINX.md)

## Tests

Tests vor Deployments ausführen, idealerweise aus der Projektwurzel:

```bash
make test-unit
make test-browser
make test
```

- `make test-unit`: führt `testthat`-Tests unter `shiny/tests/testthat/` aus (inklusive Modultests wie `test-modules.R`).
- `make test-browser`: führt Browser-Tests unter `shiny/tests/browser/` aus.
- `make test`: kombiniert beide Ziele und bricht beim ersten Fehler ab.

Falls Pakete fehlen, zuerst in R die Projektbibliothek wiederherstellen:

```r
renv::restore()
```

Browser-Tests können zusätzlich von verfügbaren Browser-/WebDriver-Komponenten abhängen.

