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
    includeScript(path = "www/custom.js")

  ),

  )
