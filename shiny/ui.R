# Sources -----------------------------------------------------------------

# source server scripts
source("source/UI/Tab1_UI.R")
source("source/UI/Tab2_UI.R")
source("source/UI/Tab3_UI.R")
source("source/UI/Tab4_UI.R")
source("source/UI/Tab5_UI.R")
source("source/UI/Tab6_UI.R")
source("source/UI/Tab7_UI.R")
source("source/UI/Tab8_UI.R")


# UI ----------------------------------------------------------------------

dashboardPage(

  help = NULL,

  # dashboardheader
  header = dashboardHeader(
    title = dashboardBrand(
      title = HTML("<strong>Klimahistorie.de</strong>"),
      color = "primary"
      ),
    status = "primary",
    controlbarIcon = NULL,
    fixed = TRUE,
    div(
      tags$a(
        href = "https://github.com/TobiasKellner/klimahistorie.de",
        target = "_blank",
        icon("github", class = "fa-lg"),
        style = "margin-right: 80px; color: white;",
        title = "https://github.com/TobiasKellner/klimahistorie.de"
      ),
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
      menuItem("Tageswerte", tabName = "tab2", icon = icon("map-marked-alt")),
      menuItem("Jahresvergleich", tabName = "tab3", icon = icon("chart-line")),
      menuItem("Tageshistorie", tabName = "tab4", icon = icon("calendar-alt")),
      menuItem("Klimarekorde", tabName = "tab5", icon = icon("trophy")),
      menuItem("Tage über & unter", tabName = "tab6", icon = icon("thermometer-half")),
      menuItem("Stationsübersicht", tabName = "overview", icon = icon("map-marker-alt")),
      menuItem("Über die Web-App", tabName = "about", icon = icon("info")),

      actionButton(
        "button1",
        HTML("Benötigen Sie Hilfe bei<br/>Datenprozessen,<br/>statistischen Auswertungen &<br/>Automatisierungen?"),
        style="color: white; background-color: #ec7063 ; border-radius: 10px !important;
        border: none; position: fixed; margin-left: 5px; bottom: 10px;"
        )

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
      collapsible = FALSE,
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

      # Tab2 - Wie war das Wetter wann und wo
      Tab2_UI_function(),

      # Tab3 - Jahresverläufe
      Tab3_UI_function(),

      # Tab4 - Tageshistorie
      Tab4_UI_function(),

      # Tab5
      Tab5_UI_function(),

      # Tab6
      Tab6_UI_function(),

      # Tab 7 - Karte
      Tab7_UI_function(),

      # Tab8 - About
      Tab8_UI_function()

      )
    )
  )
