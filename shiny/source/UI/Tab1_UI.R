Tab1_UI_function <- function() {

  tabItem(
    tabName = "tab1",
    fluidRow(
      column(
        2,
        style = "background-color: #e0e9f3;",
        selectInput('Station', HTML(paste(
          "<b>", "Stationsname", "</b>"
        )), Liste, selected = "Erfurt-Weimar")
        ,
        selectInput(
          'ycol',
          HTML(paste("<b>", "Variable", "</b>")),
          c(
            "Temperatur",
            "Schneehoehe",
            "Sonnenscheindauer",
            "Niederschlagshoehe"
          ),
          selected = names(dataset)[[1]]
        ),
        selectInput('month', HTML(paste(
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
        plotlyOutput("plot1", height = "auto")
      )
    )
  )

}
