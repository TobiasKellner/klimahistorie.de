Tab8_UI_function <- function() {

  tabItem(
    tabName = "about",
    fluidRow(
      column(
        6,
        box(
          title = HTML("&nbsp Über die Web-App"),
          status = "primary",
          width = 12,
          collapsible = FALSE,
          icon = icon("info-circle"),
          HTML(
            paste0(
              "<p style=\"text-align: justify;\">",
              "Klimahistorie.de ist eine Open-Socure Web-Anwendung zur ",
              "Visualisierung der Klimahistorie in Deutschland. ",
              "Diese Web-App ist frei und ohne jegliche Kosten nutzbar. ",
              "Die Daten stammen hierzu vom Deutschen Wetterdienst (DWD). ",
              "Entstanden ist diese Webanwendung als reines Freizeitprojekt ",
              "im Jahr 2021, damals noch unter dem Namen ",
              "<i>Prima-Klima-App.de</i>. ",
              "Ausgezeichnet wurde dieses Projekt mit dem Thüringer ",
              "Digitalpreis 2021 in der Sonderkategorie ",
              "<i>Open-Source-Lösungen</i>.</p>"
            )
          )
        )
      ),
      column(
        6,
        box(
          title = HTML("&nbsp Über meine Person"),
          status = "primary",
          width = 12,
          collapsible = FALSE,
          icon = icon("user"),
          HTML(
            paste0(
              "<p style=\"text-align: justify;\">",
              "Ich bin Tobias Kellner, der Entwickler dieser Anwendung. ",
              "Als leidenschaftlicher Programmierer und Datenanalyst wollte ",
              "ich eine Lösung zur einfachen Veranschaulichung der deutschen ",
              "Klimshistorie schaffen. ",
              "Was mit einer anfänglichen Erstellung einer Grafik des ",
              "Temperaturverlaufes anfing, entwickelte sich schnell zur ",
              "umfangreichen Web-Anwendung mit mehreren hundert ",
              "Wetterstationen.",
              "<br>",
              "Ich studierte Wirtschaftswissenschaften an den Universitäten ",
              "Erfurt und Sevilla. ",
              "Im Rahmen meines Studiums und meiner anschließenden Promotion ",
              "spezialisierte ich mich auf Datenanalyse und statistische ",
              "Programmierung. ",
              "Seit einigen Jahren arbeite ich als Programmierer für ",
              "Datenprozesse und Softwareentwicklung in einem internationalen ",
              "Mobilitätskonzern.</p>"
            )
          )
        )
      )
    ),
    fluidRow(
      column(
        6,
        box(
          title = HTML("&nbsp Pressemeldungen"),
          status = "primary",
          width = 12,
          height = "50%",
          collapsible = FALSE,
          icon = icon("newspaper"),
          tags$ul(
            tags$li(
              tags$a(
                href = "https://www.uni-erfurt.de/studium/rund-ums-studium/campusleben-blog/zahlenmann-mit-erfindergeist",
                "https://www.uni-erfurt.de/studium/rund-ums-studium/campusleben-blog/zahlenmann-mit-erfindergeist",
                target = "_blank"
              )
            ),
            tags$li(
              tags$a(
                href = "https://www.leg-thueringen.de/fileadmin/user_upload/leg_portal/downloads/publikationen/leg_thueringen/ebook_digitalisierung_leicht_erklaert.pdf",
                "https://www.leg-thueringen.de/fileadmin/user_upload/leg_portal/downloads/publikationen/leg_thueringen/ebook_digitalisierung_leicht_erklaert.pdf",
                target = "_blank"
              )
            )
          )
        )
      ),
      column(
        6,
        box(
          title = HTML("&nbsp Programmierung"),
          status = "primary",
          width = 12,
          collapsible = FALSE,
          icon = icon("laptop-code"),
          HTML(
            paste0(
              "<p style=\"text-align: justify;\">",
              "Entwickelt wurde diese Anwendung mithilfe der ",
              "Programmiersprache <strong>R</strong> und dem Erweiterungspaket <strong>Shiny</strong>. ",
              "Die Abfrage der Wetterdaten des DWD erfolgt mit dem ",
              "R-Erweiterungspaket <strong>rdwd</strong>. ",
              "Die automatisierte Ausführung der Datenabfrage erfolgt ",
              "mithilfe der Orchestrierungssoftware <strong>Apache Airflow</strong>. ",
              "Gespeichert werden die Daten in einer <strong>PostgreSQL</strong>-Datenbank. ",
              "Bereitgestellt wird diese Web-App mithilfe der ",
              "Containerisierungssoftware <strong>Docker</strong>. ",
              "Der Quellcode dieser Anwendung ist quelloffen und unter <strong>GitHub</strong> ",
              "frei verfügbar.",
              "</p>"
            )
          ),
          tags$a(
            href = "https://github.com/TobiasKellner/klimahistorie.de",
            "https://github.com/TobiasKellner/klimahistorie.de",
            target = "_blank"
          )
        )
      )
    )
  )

}
