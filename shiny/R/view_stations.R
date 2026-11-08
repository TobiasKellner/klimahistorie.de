stations_map_data <- function(db_pool, query = database_query, station = NULL) {
  if (
    !is.null(station) &&
      (length(station) != 1L ||
        is.na(station) ||
        !grepl("^[1-9][0-9]*$", as.character(station)) ||
        as.numeric(station) > .Machine$integer.max)
  ) {
    stop("Ungültige Stations-ID.", call. = FALSE)
  }
  empty <- data.frame(
    STATIONS_ID = integer(),
    Stationsname = character(),
    Bundesland = character(),
    Stationshoehe = double(),
    geoBreite = double(),
    geoLaenge = double()
  )
  if (is.null(db_pool)) {
    return(empty)
  }
  sql <- paste(
    'SELECT "STATIONS_ID", "Stationsname", "Bundesland",',
    '       "Stationshoehe", "geoBreite", "geoLaenge"',
    'FROM public."AktuelleTemperaturstationen"',
    'WHERE "geoBreite" BETWEEN -90 AND 90 AND "geoLaenge" BETWEEN -180 AND 180',
    if (!is.null(station)) 'AND "STATIONS_ID" = $1',
    'ORDER BY "Stationsname", "STATIONS_ID"'
  )
  data <- trends_query(
    db_pool,
    sql,
    params = if (!is.null(station)) list(as.integer(station)),
    query = query
  )
  if (!nrow(data)) {
    return(empty)
  }
  valid <- is.finite(data$geoBreite) &
    abs(data$geoBreite) <= 90 &
    is.finite(data$geoLaenge) &
    abs(data$geoLaenge) <= 180
  data <- data[
    valid & !duplicated(data$STATIONS_ID),
    names(empty),
    drop = FALSE
  ]
  rownames(data) <- NULL
  data
}

stations_map_labels <- function(stations) {
  text <- function(x) {
    x <- as.character(x)
    x[is.na(x) | !nzchar(x)] <- "Keine Angabe"
    htmltools::htmlEscape(x)
  }
  lapply(
    paste0(
      "<strong>",
      text(stations$Stationsname),
      "</strong><br>",
      "Bundesland: ",
      text(stations$Bundesland),
      "<br>",
      "Stationshöhe: ",
      text(stations$Stationshoehe),
      " m<br>",
      "Stations-ID: ",
      text(stations$STATIONS_ID)
    ),
    htmltools::HTML
  )
}

view_stations_ui <- function(id = "stations") {
  ns <- shiny::NS(id)
  bslib::card(
    full_screen = TRUE,
    bslib::card_header("Aktive Stationen"),
    bslib::card_body(
      leaflet::leafletOutput(ns("map"), height = "100%"),
      min_height = "600px",
      class = "stations-map-body"
    )
  )
}

view_stations_server <- function(
  id = "stations",
  db_pool = NULL,
  stations = stations_map_data
) {
  shiny::moduleServer(id, function(input, output, session) {
    data <- shiny::reactive({
      tryCatch(stations(db_pool), error = function(e) {
        shiny::validate(shiny::need(
          FALSE,
          "Die Stationskarte konnte nicht geladen werden."
        ))
      })
    })
    output$map <- leaflet::renderLeaflet({
      locations <- data()
      shiny::validate(shiny::need(
        nrow(locations) > 0L,
        "Keine aktiven Stationen mit gültigen Koordinaten verfügbar oder keine Datenbank konfiguriert."
      ))
      labels <- stations_map_labels(locations)
      map <- leaflet::leaflet(locations) |>
        leaflet::addTiles() |>
        leaflet::addAwesomeMarkers(
          lng = ~geoLaenge,
          lat = ~geoBreite,
          layerId = ~ as.character(STATIONS_ID),
          icon = leaflet::awesomeIcons(
            icon = "circle",
            library = "fa",
            markerColor = "blue",
            iconColor = "#FFFFFF"
          ),
          label = labels,
          popup = labels
        )
      if (nrow(locations) == 1L) {
        map |>
          leaflet::setView(
            locations$geoLaenge[[1]],
            locations$geoBreite[[1]],
            zoom = 10
          )
      } else {
        map |>
          leaflet::fitBounds(
            min(locations$geoLaenge),
            min(locations$geoBreite),
            max(locations$geoLaenge),
            max(locations$geoBreite)
          )
      }
    })
    data
  })
}
