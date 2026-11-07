view_about_ui <- function() {
  bslib::layout_columns(
    col_widths = c(6, 6),
    bslib::card(
      bslib::card_header("Über die Web-App"),
      shiny::p("Platzhaltertext")
    ),
    bslib::card(
      bslib::card_header("Über meine Person"),
      shiny::p("Platzhaltertext")
    )
  )
}
