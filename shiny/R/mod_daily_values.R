mod_daily_values_ui <- function(id) {
  ns <- shiny::NS(id)

  filter_card_ui(
    title = shiny::tags$div(
      class = "d-flex justify-content-between align-items-center w-100",
      shiny::tags$span("Tageswerte"),
      shiny::actionButton(
        ns("show_map"),
        "Karte",
        icon = shiny::icon("map"),
        class = "btn-sm btn-success"
      )
    ),
    sidebar_id = ns("filters"),
    controls = shiny::tagList(
      shiny::selectInput(
        ns("station"),
        "Standort",
        choices = app_station_choices()
      ),
      shiny::dateInput(
        ns("date"),
        "Datum",
        value = daily_values_default_date(),
        max = Sys.Date(),
        language = "de",
        format = "dd.mm.yyyy",
        startview = "decade"
      )
    ),
    content = bslib::card_body(
      shiny::uiOutput(ns("description")),
      shiny::uiOutput(ns("values")),
      fillable = FALSE
    )
  )
}

mod_daily_values_server <- function(
  id,
  db_pool = NULL,
  stations = trends_station_choices,
  daily = daily_values_data,
  location = function(pool, station) stations_map_data(pool, station = station),
  show = shiny::showModal
) {
  shiny::moduleServer(id, function(input, output, session) {
    station_choices <- shiny::reactiveVal(character())
    station_error <- shiny::reactiveVal(NULL)
    shiny::observeEvent(
      TRUE,
      {
        choices <- tryCatch(stations(db_pool), error = function(e) {
          station_error("Die Stationsliste konnte nicht geladen werden.")
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
    data <- shiny::reactive({
      shiny::validate(shiny::need(is.null(station_error()), station_error()))
      shiny::validate(shiny::need(
        length(station_choices()) > 0L,
        "Keine Stationen verfügbar oder keine Datenbank konfiguriert."
      ))
      shiny::req(input$station %in% station_choices(), input$date)
      tryCatch(daily(db_pool, input$station, input$date), error = function(e) {
        shiny::validate(shiny::need(
          FALSE,
          "Die Tagesdaten konnten nicht geladen werden."
        ))
      })
    })
    map_location <- shiny::reactiveVal(NULL)
    shiny::observeEvent(input$show_map, {
      shiny::req(input$station %in% station_choices())
      selected <- tryCatch(
        location(db_pool, input$station),
        error = function(e) NULL
      )
      map_location(selected)
      label <- names(station_choices())[match(input$station, station_choices())]
      content <- if (is.null(selected) || nrow(selected) != 1L) {
        shiny::p("Die Stationskarte ist für diesen Standort nicht verfügbar.")
      } else {
        leaflet::leafletOutput(session$ns("station_map"), height = "450px")
      }
      show(shiny::modalDialog(
        title = paste("Wetterstation:", label),
        content,
        size = "l",
        easyClose = TRUE,
        footer = shiny::modalButton("Schließen", icon = shiny::icon("xmark"))
      ))
    })
    output$station_map <- leaflet::renderLeaflet({
      selected <- map_location()
      shiny::req(!is.null(selected), nrow(selected) == 1L)
      labels <- stations_map_labels(selected)
      leaflet::leaflet(selected) |>
        leaflet::addTiles() |>
        leaflet::addAwesomeMarkers(
          lng = ~geoLaenge,
          lat = ~geoBreite,
          icon = leaflet::awesomeIcons(
            icon = "circle",
            library = "fa",
            markerColor = "blue",
            iconColor = "#FFFFFF"
          ),
          label = labels,
          popup = labels
        ) |>
        leaflet::setView(
          selected$geoLaenge[[1]],
          selected$geoBreite[[1]],
          zoom = 10
        )
    })
    output$description <- shiny::renderUI({
      shiny::req(input$station %in% station_choices(), input$date)
      label <- names(station_choices())[match(input$station, station_choices())]
      shiny::p(
        "Wetterdaten für den Standort ",
        shiny::strong(label),
        " am ",
        shiny::strong(format(input$date, "%d.%m.%Y")),
        "."
      )
    })
    output$values <- shiny::renderUI({
      values <- data()
      metrics <- daily_values_metrics()
      boxes <- lapply(seq_len(nrow(metrics)), function(i) {
        bslib::value_box(
          title = metrics$label[[i]],
          value = daily_values_format(
            values[[metrics$column[[i]]]],
            metrics$unit[[i]]
          ),
          shiny::p(paste("am", format(input$date, "%d.%m.%Y"))),
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
    shiny::reactive(list(station = input$station, date = input$date))
  })
}
