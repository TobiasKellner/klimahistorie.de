Tab1_UI_function <- function() {

  tabItem(
    tabName = "tab1",
    fluidRow(
      style = "display: flex; align-items: stretch;",
      column(
        width = 2,
        style = "padding: 0px;",

        box(
          collapsible = FALSE,
          title = "Einstellungen",
          width = 12,
          icon = icon("gear"),
          status = "primary",
          solidHeader = TRUE,
          selectInput(
            'Variable1',
            HTML(paste("<b>", "Variable", "</b>")),
            c(
              "Lufttemperatur",
              "Schneehoehe",
              "Sonnenscheindauer",
              "Niederschlagshoehe"
            )
          ),
          selectInput('month1', HTML(paste("<b>", "Jahr / Monat", "</b>")), c(month_list), selected = "Gesamtes Jahr"),
          radioButtons(
            "current_year",
            HTML(
              paste(
                "<b>Aktuelles Jahr anzeigen?</b>",
                "(Bisheriger Durchschnittswert)",
                sep = "<br/>"
              )
            ),
            c("Ja" = TRUE, "Nein" = FALSE),
            selected = FALSE,
            inline = T
          ),
          radioButtons(
            "regline",
            HTML(
              paste("<b>Trendlinie:</b>", "(Regressionsgerade)", sep = "<br/>")
            ),
            c("Ja" = TRUE, "Nein" = FALSE),
            selected = FALSE,
            inline = T
          )
        )

      ),
      column(
        10,
        bs4InfoBox(
          title = uiOutput("description1"),
          icon = icon("info-circle"),
          color = "primary",
          width = 12
        ),
        withSpinner(plotlyOutput("plot1", height = "calc(100vh - 250px)"))
      )
    )
  )

}
