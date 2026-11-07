# Sources -----------------------------------------------------------------

source("source/UI/Tab1_UI.R")
source("source/UI/Tab2_UI.R")
source("source/UI/Tab3_UI.R")
source("source/UI/Tab4_UI.R")
source("source/UI/Tab5_UI.R")
source("source/UI/Tab6_UI.R")
source("source/UI/Tab7_UI.R")
source("source/UI/Tab8_UI.R")


# UI ----------------------------------------------------------------------

app_content <- navset_tab(
  nav_panel("Durchschnitte & Trends", Tab1_UI_function()),
  nav_panel("Tageswerte", Tab2_UI_function()),
  nav_panel("Jahresvergleich", Tab3_UI_function()),
  nav_panel("Tageshistorie", Tab4_UI_function()),
  nav_panel("Klimarekorde", Tab5_UI_function()),
  nav_panel("Tage über & unter", Tab6_UI_function()),
  nav_panel("Stationsübersicht", Tab7_UI_function()),
  nav_panel("Über die Web-App", Tab8_UI_function()),
  id = "main_nav"
)

bslib::page_sidebar(
  title = div(
    style = "display: flex; align-items: center; gap: 10px;",
    tags$a(
      href = "https://klimahistorie.de",
      target = "_blank",
      tags$img(
        src = "logo.png",
        alt = "Klimahistorie.de",
        style = "height: 32px; width: auto; display: block;"
      )
    ),
    tags$strong("Klimahistorie.de")
  ),
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
  sidebar = bslib::sidebar(
    id = "sidebar",
    title = "Standort",
    icon = icon("location-dot"),
    selectizeInput(
      "selectLocation",
      "Standort auswählen:",
      stations_liste,
      selected = stations_liste[1]
    ),
    leafletOutput("mymap", height = "260px"),
    hr(),
    actionButton(
      inputId = "button1",
      label = "Kontakt",
      icon = icon("hand-pointer"),
      class = "btn-danger"
    ),
    tags$div(
      style = "margin-top: 12px;",
      tags$a(
        href = "https://github.com/TobiasKellner/klimahistorie.de",
        target = "_blank",
        icon("github", class = "fa-lg"),
        " GitHub"
      )
    )
  ),
  useShinyjs(),
  includeCSS("www/custom.css"),
  includeScript(path = "www/custom.js"),
  app_content
)
