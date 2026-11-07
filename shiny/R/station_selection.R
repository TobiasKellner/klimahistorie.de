station_default_selection <- function(choices) {
  preferred <- which(names(choices) == "Erfurt-Weimar")
  if (length(preferred)) {
    return(unname(choices[[preferred[[1L]]]]))
  }
  if (length(choices)) unname(choices[[1L]]) else character()
}

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
        selected = station_default_selection(choices)
      )
    },
    once = TRUE
  )
  station_choices
}
