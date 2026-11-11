# klimahistorie.de
Eine Shiny-Web-Anwendung zur Visualisierung der deutschen Klimahistorie

Die aktuelle, modulare App liegt unter [`shiny/`](shiny/README.md).
Start aus der Projektwurzel: `shiny::runApp("shiny")`.
Architektur und Testbefehle sind in der [App-Dokumentation](shiny/README.md) beschrieben.

Die bisherige App bleibt unter `shiny_old/` als Orientierungshilfe erhalten.
Docker bindet die aktuelle App aus `shiny/` ein; die Importskripte verwenden
`etl/db_connection.R`. Siehe [ETL-Dokumentation](etl/README.md).

Build, Start und Betrieb des Produktionscontainers sind in der
[Docker-Dokumentation](docker/README.md) beschrieben.

Eine ausführliche [Deployment- und Nginx-Anleitung](docker/DEPLOYMENT-NGINX.md)
beschreibt den Betrieb auf AlmaLinux mit vorhandenem Host-Nginx, HTTPS,
Zertifikatserneuerung, Datenbank, Updates, Backups und Fehlerdiagnose.
