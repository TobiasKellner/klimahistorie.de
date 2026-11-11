view_about_ui <- function() {
  external_link <- function(label, href) {
    shiny::tags$a(
      label,
      href = href,
      target = "_blank",
      rel = "noopener noreferrer"
    )
  }
  bslib::layout_columns(
    col_widths = bslib::breakpoints(sm = 12, lg = 6),
    fill = FALSE,
    bslib::card(
      bslib::card_header(shiny::icon("circle-info"), " Über Klimashistorie.de"),
      shiny::p(
        "Klimahistorie.de ist eine frei und kostenlos nutzbare Open-Source-Webanwendung ",
        "zur Visualisierung der Klimahistorie in Deutschland. Sie macht die ",
        "Messdaten des Deutschen Wetterdienstes (DWD) interaktiv zugänglich – ",
        "von einzelnen Tageswerten bis zu langjährigen Entwicklungen."
      ),
      shiny::p(
        "Entstanden ist die Anwendung 2021 als Freizeitprojekt unter dem Namen ",
        shiny::em("Prima-Klima-App.de"),
        ". Das Projekt wurde mit dem Thüringer ",
        "Digitalpreis 2021 in der Sonderkategorie ",
        shiny::em("Open-Source-Lösungen"),
        " ausgezeichnet."
      ),
      shiny::p(
        "Heute bieten Stationskarten, Jahresvergleiche, Klimarekorde und ",
        "der Tab „Klima auf einen Blick“ verschiedene Zugänge zur lokalen Klimageschichte."
      )
    ),
    bslib::card(
      bslib::card_header(shiny::icon("user"), " Über den Entwickler"),
      shiny::p(
        "Ich bin Tobias Kellner, der Entwickler dieser Anwendung. Als ",
        "leidenschaftlicher Programmierer und Datenanalyst wollte ich eine ",
        "einfache Möglichkeit schaffen, die deutsche Klimahistorie zu erkunden."
      ),
      shiny::p(
        "Aus einer ersten Grafik zum Temperaturverlauf entwickelte sich eine ",
        "umfangreiche Webanwendung für zahlreiche Wetterstationen. Mein ",
        "Hintergrund liegt in den Wirtschaftswissenschaften, der Datenanalyse ",
        "und der statistischen Programmierung."
      ),
      shiny::p(
        "Für Fragen, Rückmeldungen oder Unterstützung bei Datenanalysen ",
        "steht der Kontakt-Button in der Seitenleiste zur Verfügung."
      )
    ),
    bslib::card(
      bslib::card_header(shiny::icon("database"), " Datenquelle und Methodik"),
      shiny::p(
        "Die Auswertungen basieren auf stationsbezogenen Tagesdaten des ",
        "Deutschen Wetterdienstes. Welche Stationen und Zeiträume dargestellt ",
        "werden können, hängt vom Datenangebot und den importierten Messwerten ab."
      ),
      shiny::p(
        "Fehlende Werte und der DWD-Fehlwert −999 werden nicht als Messwerte ",
        "ausgewertet. Die Regeln zur Vollständigkeit sind abhängig von der jeweiligen ",
        "Ansicht und werden dort erläutert."
      ),
      shiny::p(
        "Im Klima-Überblick werden Jahreskennzahlen nur für vollständige ",
        "Kalenderjahre angezeigt. Ein Referenzwert für 1991–2020 setzt je Kennzahl ",
        "30 vollständige Jahre voraus."
      ),
      shiny::p(
        class = "text-muted",
        "Stationsverlegungen und Änderungen der Messbedingungen können die ",
        "Vergleichbarkeit beeinflussen. Die App homogenisiert die Stationsreihen ",
        "nicht. Eine einzelne Station beschreibt nicht das Klima ganz Deutschlands."
      ),
      external_link(
        "DWD Climate Data Center – tägliche Klimadaten",
        "https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily/kl/"
      )
    ),
    bslib::card(
      bslib::card_header(shiny::icon("laptop-code"), " Technik und Quellcode"),
      shiny::p(
        "Die Anwendung wird mit ",
        shiny::strong("R"),
        " und ",
        shiny::strong("Shiny"),
        " entwickelt. Die Oberfläche nutzt ",
        shiny::strong("bslib"),
        " für responsive Navigation, Karten und Kennzahlen."
      ),
      shiny::p(
        "Der Import der DWD-Daten erfolgt mit dem R-Paket ",
        shiny::strong("rdwd"),
        ". Die Messwerte werden in einer ",
        shiny::strong("PostgreSQL"),
        "-Datenbank gespeichert. Die Web-App wird ",
        "über ",
        shiny::strong("Docker"),
        " und einen Nginx-Reverse-Proxy bereitgestellt."
      ),
      shiny::p(
        "Der Quellcode und die technische Dokumentation sind öffentlich ",
        "auf GitHub verfügbar. Rückmeldungen und Verbesserungsvorschläge sind willkommen."
      ),
      external_link(
        "Quellcode und Dokumentation auf GitHub",
        "https://github.com/TobiasKellner/klimahistorie.de"
      )
    ),
    bslib::card(
      bslib::card_header(
        shiny::icon("newspaper"),
        " Presse und Projektgeschichte"
      ),
      shiny::p("Weitere Hintergründe zum Projekt und seiner Entstehung:"),
      shiny::p(external_link(
        "Universität Erfurt: Zahlenmann mit Erfindergeist",
        "https://www.uni-erfurt.de/studium/rund-ums-studium/campusleben-blog/zahlenmann-mit-erfindergeist"
      )),
      shiny::p(external_link(
        "LEG Thüringen: Digitalisierung leicht erklärt (PDF)",
        "https://www.leg-thueringen.de/fileadmin/user_upload/leg_portal/downloads/publikationen/leg_thueringen/ebook_digitalisierung_leicht_erklaert.pdf"
      ))
    )
  )
}
