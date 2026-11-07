station_selection_server <- function(session, db_pool, stations) {
  station_choices <- shiny::reactiveVal(character())
  shiny::observeEvent(
    TRUE,
    {
      choices <- tryCatch(stations(db_pool), error = function(e) {
        shiny::showNotification(
          "Die Stationsliste konnte nicht geladen werden.",
          type = "error",
          session = session
        )
        character()
      })
      station_choices(choices)
      shiny::updateSelectInput(
        session,
        "station",
        choices = choices,
        selected = if (length(choices)) unname(choices[[1L]]) else character()
      )
    },
    once = TRUE
  )
  station_choices
}
