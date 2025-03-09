# Sources -----------------------------------------------------------------

# source server scripts
source("source/UI/Tab1_UI.R")
source("source/UI/Tab7_UI.R")
source("source/UI/Tab8_UI.R")


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
      style = "padding-left: 5px; padding-right: 5px;",
      title = "Standort",
      width = 12,
      icon = icon("location-dot"),
      status = "primary",
      selectizeInput(
        "selectLocation",
        "Standort auswählen:",
        Stationsliste,
        selected = Stationsliste[1]
      ),
      leafletOutput("mymap")
    )
  ),

  # body
  body = dashboardBody(

    useShinyjs(),
    includeCSS("www/custom.css"),
    includeScript(path = "www/custom.js"),

    tabItems(

      # Tab1 - Durchschnitte & Trends
      Tab1_UI_function(),

      # Tab 7 - Karte
      Tab7_UI_function(),

      # Tab8 - About
      Tab8_UI_function()

      )
    )
  )
