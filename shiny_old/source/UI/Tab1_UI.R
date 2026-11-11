Tab1_UI_function <- function() {
  bslib::layout_columns(
    col_widths = c(4, 8),
    bslib::card(
      full_screen = FALSE,
      bslib::card_header("Einstellungen"),
      selectInput(
        "Variable1",
        HTML("<b>Variable</b>"),
        c(
          "Lufttemperatur",
          "Schneehoehe",
          "Sonnenscheindauer",
          "Niederschlagshoehe"
        )
      ),
      selectInput(
        "month1",
        HTML("<b>Jahr / Monat</b>"),
        choices = month_list,
        selected = 0
      ),
      radioButtons(
        "current_year",
        HTML(
          "<b>Aktuelles Jahr anzeigen?</b><br/>(Bisheriger Durchschnittswert)"
        ),
        c("Ja" = TRUE, "Nein" = FALSE),
        selected = FALSE,
        inline = TRUE
      ),
      radioButtons(
        "regline",
        HTML("<b>Trendlinie:</b><br/>(Regressionsgerade)"),
        c("Ja" = TRUE, "Nein" = FALSE),
        selected = FALSE,
        inline = TRUE
      )
    ),
    bslib::card(
      full_screen = TRUE,
      bslib::card_header(uiOutput("description1")),
      withSpinner(plotlyOutput("plot1", height = "calc(100vh - 250px)"))
    )
  )
}
