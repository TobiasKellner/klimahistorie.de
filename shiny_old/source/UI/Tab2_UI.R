Tab2_UI_function <- function() {
  bslib::layout_columns(
    col_widths = c(4, 8),
    bslib::card(
      bslib::card_header("Einstellungen"),
      dateInput(
        "date2",
        HTML("<b>Datum:</b>"),
        value = today() - months(1),
        max = today(),
        startview = "decade"
      )
    ),
    bslib::card(
      bslib::card_header(uiOutput("description2")),
      br(),
      fluidRow(
        valueBoxOutput("box1"),
        valueBoxOutput("box2"),
        valueBoxOutput("box3")
      ),
      fluidRow(
        valueBoxOutput("box4"),
        valueBoxOutput("box5"),
        valueBoxOutput("box6")
      ),
      fluidRow(
        valueBoxOutput("box7"),
        valueBoxOutput("box8"),
        valueBoxOutput("box9")
      )
    )
  )
}
