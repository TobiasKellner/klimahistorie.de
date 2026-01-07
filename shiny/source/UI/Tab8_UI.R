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
              "Klimahistorie.de ist eine nutzerfreundliche Open-Socure Web-Anwendung zur Visualisierung der Klimahistorie in Deutschland. ",
              "Diese Web-App ist frei und ohne jegliche Kosten nutzbar. ",
              "Die Daten stammen hierzu vom Deutschen Wetterdienst (DWD). ",
              "Entstanden ist diese Webanwendung als reines Freizeitprojekt im Jahr 2021, damals noch unter dem Namen 'Prima-Klima-App.de'. ",
              "Ausgezeichnet wurde dieses Projekt mit dem Thüringer Digitalpreis in der Sonderkategorie 'Open-Source-Lösungen'.",
              "</p>"
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
              "Hallo, ich bin Tobias Kellner, der Entwickler dieser Anwendung. ",
              "Als leidenschaftlicher Open-Source-Enthusiast und Entwickler wollte ich eine Lösung für [spezifisches Problem] schaffen, die sowohl einfach als auch effizient ist.",
              "</p>"
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
          tags$a(
            href = "https://www.uni-erfurt.de/studium/rund-ums-studium/campusleben-blog/zahlenmann-mit-erfindergeist",
            "https://www.uni-erfurt.de/studium/rund-ums-studium/campusleben-blog/zahlenmann-mit-erfindergeist",
            target = "_blank"
          ),
          br(),
          tags$a(
            href = "https://www.leg-thueringen.de/fileadmin/user_upload/leg_portal/downloads/publikationen/leg_thueringen/ebook_digitalisierung_leicht_erklaert.pdf",
            "https://www.leg-thueringen.de/fileadmin/user_upload/leg_portal/downloads/publikationen/leg_thueringen/ebook_digitalisierung_leicht_erklaert.pdf",
            target = "_blank"
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
              "Entwickelt wurde diese Anwendung mithilfe der Programmiersprache R und dem Erweiterungspaket Shiny. ",
              "Bereitgestellt wird diese Web-App mithilfe der Containerisierungssoftware Docker. ",
              "Der Quellcode dieser Anwendung ist quelloffen und unter GitHub frei verfügbar.",
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
