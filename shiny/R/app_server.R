navigation_server <- function(input, session, select = bslib::nav_select) {
  shiny::observeEvent(input$sidebar_tabs, {
    shiny::req(input$sidebar_tabs %in% app_navigation()$id)
    select("main_tabs", input$sidebar_tabs, session = session)
  })
}

app_server <- function(
  input,
  output,
  session,
  db_pool = NULL,
  stations = trends_station_choices
) {
  session$userData$db_pool <- db_pool
  navigation_server(input, session)
  contact_server(input, session)
  view_stations_server("stations", db_pool = db_pool)
  # All tabs share one metadata snapshot per browser session.
  station_snapshot <- shiny::reactive(stations(db_pool))
  station_provider <- function(pool) station_snapshot()
  mod_trends_server("trends", db_pool = db_pool, stations = station_provider)
  mod_daily_values_server(
    "daily_values",
    db_pool = db_pool,
    stations = station_provider
  )
  mod_year_comparison_server(
    "year_comparison",
    db_pool = db_pool,
    stations = station_provider
  )
  mod_daily_history_server(
    "daily_history",
    db_pool = db_pool,
    stations = station_provider
  )
  mod_records_server("records", db_pool = db_pool, stations = station_provider)
  mod_thresholds_server(
    "thresholds",
    db_pool = db_pool,
    stations = station_provider
  )
}
