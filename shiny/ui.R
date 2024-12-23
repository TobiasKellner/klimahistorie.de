# Sources -----------------------------------------------------------------



# UI ----------------------------------------------------------------------

dashboardPage(

  help = NULL,

  # dashboardheader
  header = dashboardHeader(
    title = dashboardBrand("Klimahistorie.de", color = "primary"),
    status = "primary",
    controlbarIcon = NULL,
    fixed = TRUE,
    div(
      actionButton(
        "update_kontrollbar",
        label = "Kontrollleiste",
        icon = icon("bars-progress"),
        status = "danger"
      ),
      style = "position: absolute; right: 20px;"
    )
    ),

  # sidebar
  sidebar = dashboardSidebar(
    status = "primary",
    sidebarMenu(

      menuItem("Durchschnitte & Trends", tabName = "tab1", icon = icon("chart-simple")),

      menuItem(
        "Wie war das Wetter wann & wo?",
        tabName = "tab2",
        icon = icon("map-marked-alt")
      ),
      menuItem("Jahresverläufe im Vergleich", tabName = "trends", icon = icon("chart-line")),
      menuItem("Tageshistorie", tabName = "dayhistory", icon = icon("calendar-alt")),
      menuItem("Klimarekorde", tabName = "records", icon = icon("trophy")),
      menuItem("Tage über & unter", tabName = "over", icon = icon("thermometer-half")),
      menuItem("Übersicht Wetterstationen", tabName = "overview", icon = icon("map-marker-alt")),
      menuItem("Über die Web-App", tabName = "about", icon = icon("info")),

      actionButton("button1", HTML("Benötigen Sie Hilfe zu<br/>statistischen Auswertungen,<br/>Datenanalysen &<br/>Visualisierungen?"),
                   style="color: white; background-color: #ec7063 ; border-radius: 10px !important;
                border: none; position: fixed; margin-left: 5px; bottom: 10px;")

    )

      ),

  # controlbar
  controlbar = dashboardControlbar(
    id = "controlbar",
    skin = "light",
    pinned = TRUE,
    collapsed = FALSE,
    overlay = FALSE,
    box(
      id = "boxLocation",
      title = "Standort",
      width = 12,
      icon = icon("location-dot"),
      status = "primary",
      selectizeInput(
        "selectLocation",
        "Standort auswählen:",
        choices = c("Berlin", "Hamburg")
      )
    )
  ),

  # body
  body = dashboardBody(

    useShinyjs(),
    includeCSS("www/custom.css"),
    includeScript(path = "www/custom.js"),

    tabItems(
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
              collapsible = FALSE,
              icon = icon("newspaper"),
              HTML(
                "Test"
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
                  "</p>"
                )
              )
            )
          )
          )
        )
      )
    )
  )
