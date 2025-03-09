Tab1_UI_function <- function() {

  tabItem(
    tabName = "tab1",
    fluidRow(
      column(
        2,
        style = "background-color: #e0e9f3;",
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
        selectInput('month1', HTML(paste(
          "<b>", "Jahr / Monat", "</b>"
        )), c(month_list), selected = "Gesamtes Jahr"),
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
        )
        ,
        radioButtons(
          "regline",
          HTML(
            paste("<b>Trendlinie:</b>", "(Regressionsgerade)", sep = "<br/>")
          ),
          c("Ja" = TRUE, "Nein" = FALSE),
          selected = FALSE,
          inline = T
        )
      ),
      column(
        10,
        uiOutput("header_text"),
        uiOutput("description1"),
        withSpinner(plotlyOutput("plot1", height = "calc(100vh - 250px)"))
      )
    )
  )

}
