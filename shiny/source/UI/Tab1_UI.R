Tab1_UI_function <- function() {

  tabItem(
    tabName = "tab1",
    fluidRow(
      column(
        2,
        style = "
        background-color: #007bff1a;
        padding: 10px;
        border-radius: 5px;
        ",
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
