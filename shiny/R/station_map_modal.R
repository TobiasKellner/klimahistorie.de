station_map_header <- function(title, ns) {
  shiny::tags$div(
    class = "d-flex justify-content-between align-items-center w-100",
    shiny::tags$span(title),
    shiny::actionButton(
      ns("show_map"),
      "Karte",
      icon = shiny::icon("map"),
      class = "btn-sm btn-success"
    )
  )
}

station_map_modal_server <- function(
  input,
  output,
  session,
  db_pool,
  choices,
  location = function(pool, station) stations_map_data(pool, station = station),
  show = shiny::showModal
) {
  map_location <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$show_map, {
    shiny::req(input$station %in% choices())
    selected <- tryCatch(location(db_pool, input$station), error = function(e) {
      NULL
    })
    map_location(selected)
    label <- names(choices())[match(input$station, choices())]
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
}
