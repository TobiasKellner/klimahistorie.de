mod_records_ui <- function(id) {
  ns <- shiny::NS(id)

  filter_card_ui(
    title = station_map_header("Klimarekorde", ns),
    sidebar_id = ns("filters"),
    controls = shiny::tagList(
      shiny::selectInput(
        ns("station"),
        "Standort",
        choices = app_station_choices()
      ),
      shiny::radioButtons(
        ns("record_type"),
        "Maximum / Minimum",
        choices = c("Maximum", "Minimum"),
        inline = TRUE
      )
    ),
    content = bslib::card_body(
      shiny::uiOutput(ns("description")),
      shiny::uiOutput(ns("values")),
      fillable = FALSE
    )
  )
}

mod_records_server <- function(
  id,
  db_pool = NULL,
  stations = trends_station_choices,
  location = function(pool, station) stations_map_data(pool, station = station),
  show = shiny::showModal,
  records = records_data
) {
  shiny::moduleServer(id, function(input, output, session) {
    choices <- station_selection_server(session, db_pool, stations)
    station_map_modal_server(
      input,
      output,
      session,
      db_pool,
      choices,
      location,
      show
    )
    data <- shiny::reactive({
      shiny::validate(shiny::need(
        length(choices()) > 0L,
        "Keine Stationen verfügbar oder keine Datenbank konfiguriert."
      ))
      shiny::req(input$station %in% choices(), input$record_type)
      tryCatch(
        records(db_pool, input$station, input$record_type),
        error = function(e) {
          shiny::validate(shiny::need(
            FALSE,
            "Die Klimarekorde konnten nicht geladen werden."
          ))
        }
      )
    })
    output$description <- shiny::renderUI({
      shiny::req(input$station %in% choices(), input$record_type)
      label <- names(choices())[match(input$station, choices())]
      shiny::p(
        shiny::strong(input$record_type),
        " der verfügbaren Tagesmessungen am Standort ",
        shiny::strong(label),
        ". Bei gleichen Rekordwerten wird das früheste Datum angezeigt.",
        " Fehlende Messwerte werden ausgeschlossen."
      )
    })
    output$values <- shiny::renderUI({
      values <- data()
      metrics <- daily_values_metrics()
      boxes <- lapply(seq_len(nrow(metrics)), function(i) {
        row <- values[match(metrics$column[[i]], values$column), , drop = FALSE]
        bslib::value_box(
          title = metrics$label[[i]],
          value = daily_values_format(row$value, metrics$unit[[i]]),
          shiny::p(
            if (is.na(row$date)) {
              "Kein gültiger Messwert verfügbar"
            } else {
              paste("am", format(row$date, "%d.%m.%Y"))
            }
          ),
          showcase = shiny::icon(metrics$icon[[i]]),
          theme = "primary",
          fill = FALSE
        )
      })
      do.call(
        bslib::layout_columns,
        c(
          boxes,
          list(
            col_widths = bslib::breakpoints(sm = 6, lg = 4),
            fill = FALSE
          )
        )
      )
    })
    shiny::reactive(list(
      station = input$station,
      record_type = input$record_type
    ))
  })
}
