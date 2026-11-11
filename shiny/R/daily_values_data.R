daily_values_metrics <- function() {
  data.frame(
    column = c("TMK", "TNK", "TXK", "SDK", "RSK", "SHK_TAG", "FM", "FX", "PM"),
    label = c(
      "Durchschnittstemperatur",
      "Minimaltemperatur",
      "Maximaltemperatur",
      "Sonnenscheindauer",
      "Niederschlagshöhe",
      "Schneehöhe",
      "Windgeschwindigkeit",
      "Windspitze",
      "Luftdruck (Tagesmittel)"
    ),
    unit = c("°C", "°C", "°C", "Stunden", "mm", "cm", "m/s", "m/s", "hPa"),
    icon = c(
      "temperature-half",
      "temperature-empty",
      "temperature-full",
      "sun",
      "umbrella",
      "snowflake",
      "wind",
      "arrow-right",
      "gauge-high"
    )
  )
}

daily_values_default_date <- function(today = Sys.Date()) {
  # Roll month-end dates back to the last valid day of the previous month.
  lubridate::`%m-%`(today, lubridate::period(months = 1))
}

daily_values_data <- function(db_pool, station, date, query = database_query) {
  if (
    length(station) != 1L ||
      is.na(station) ||
      !grepl("^[1-9][0-9]*$", as.character(station)) ||
      as.numeric(station) > .Machine$integer.max
  ) {
    stop("Ungültige Stations-ID.", call. = FALSE)
  }
  if (!inherits(date, "Date") || length(date) != 1L || is.na(date)) {
    stop("Ungültiges Datum.", call. = FALSE)
  }
  columns <- daily_values_metrics()$column
  empty <- as.data.frame(stats::setNames(
    rep(list(numeric()), length(columns)),
    columns
  ))
  if (is.null(db_pool)) {
    return(empty)
  }
  sql <- paste(
    "SELECT",
    paste(sprintf('"%s"', columns), collapse = ", "),
    'FROM public."Tagesdaten"',
    'WHERE "STATIONS_ID" = $1 AND "MESS_DATUM" = $2::text'
  )
  data <- trends_query(
    db_pool,
    sql,
    params = list(as.integer(station), format(date, "%Y%m%d")),
    query = query
  )
  if (!nrow(data)) {
    return(empty)
  }
  if (nrow(data) != 1L || !setequal(names(data), columns)) {
    stop("Unerwartete Tagesdatenstruktur.", call. = FALSE)
  }
  data <- data[columns]
  data[] <- lapply(data, function(value) {
    value[!is.finite(value) | value == -999] <- NA_real_
    value
  })
  data
}

daily_values_format <- function(value, unit) {
  if (!length(value) || is.na(value) || !is.finite(value) || value == -999) {
    return("Nicht verfügbar")
  }
  paste(
    format(round(value, 1), nsmall = 1, decimal.mark = ",", trim = TRUE),
    unit
  )
}
