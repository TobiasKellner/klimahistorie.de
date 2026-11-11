trends_variables <- function() {
  data.frame(
    name = c(
      "Lufttemperatur",
      "Schneehoehe",
      "Sonnenscheindauer",
      "Niederschlagshoehe"
    ),
    column = c("TMK", "SHK_TAG", "SDK", "RSK"),
    unit = c("°C", "cm", "Stunden/Tag", "mm/Tag"),
    stringsAsFactors = FALSE
  )
}

trends_month_choices <- function() {
  stats::setNames(
    as.character(0:12),
    c(
      "Gesamtes Jahr",
      "Januar",
      "Februar",
      "März",
      "April",
      "Mai",
      "Juni",
      "Juli",
      "August",
      "September",
      "Oktober",
      "November",
      "Dezember"
    )
  )
}

# Do not expose connection strings, SQL, or credentials from provider errors.
trends_query <- function(db_pool, sql, params = NULL, query = database_query) {
  tryCatch(
    query(db_pool, sql, params = params),
    error = function(e) {
      stop(
        "Die Klimadaten konnten nicht geladen werden. Bitte versuchen Sie es später erneut.",
        call. = FALSE
      )
    }
  )
}

trends_station_choices <- function(db_pool, query = database_query) {
  if (is.null(db_pool)) {
    return(stats::setNames(character(), character()))
  }
  sql <- paste(
    'SELECT "STATIONS_ID" AS id, "Stationsname" AS name',
    'FROM public."AktuelleTemperaturstationen"',
    'ORDER BY "Stationsname", "STATIONS_ID"',
    sep = "\n"
  )
  stations <- trends_query(db_pool, sql, query = query)
  if (!nrow(stations)) {
    return(stats::setNames(character(), character()))
  }
  stations <- stations[!duplicated(stations$id), , drop = FALSE]
  ids <- as.character(stations$id)
  station_names <- as.character(stations$name)
  station_names[is.na(station_names) | !nzchar(station_names)] <- "Station"
  ordering <- order(station_names, ids)
  stats::setNames(ids[ordering], station_names[ordering])
}

trends_empty_annual <- function() {
  data.frame(year = integer(), value = double(), n_days = integer())
}

trends_annual_data <- function(
  db_pool,
  station,
  variable,
  month = 0,
  include_current = FALSE,
  today = Sys.Date(),
  query = database_query
) {
  # Shiny select inputs arrive as strings; accept only complete integer tokens.
  valid_integer <- function(x, lower, upper) {
    if (length(x) != 1L || is.object(x) || is.na(x)) {
      return(FALSE)
    }
    if (is.character(x)) {
      if (!grepl("^(0|[1-9][0-9]*)$", x)) {
        return(FALSE)
      }
      x <- suppressWarnings(as.numeric(x))
    }
    is.numeric(x) && is.finite(x) && x == trunc(x) && x >= lower && x <= upper
  }
  if (!valid_integer(station, 1, .Machine$integer.max)) {
    stop("Ungültige Stations-ID.", call. = FALSE)
  }
  variables <- trends_variables()
  if (
    !is.character(variable) ||
      length(variable) != 1L ||
      is.na(variable) ||
      !variable %in% variables$name
  ) {
    stop("Ungültige Klimavariable.", call. = FALSE)
  }
  if (!valid_integer(month, 0, 12)) {
    stop("Ungültiger Monat.", call. = FALSE)
  }
  if (
    !is.logical(include_current) ||
      length(include_current) != 1L ||
      is.na(include_current)
  ) {
    stop("Ungültige Auswahl für das laufende Jahr.", call. = FALSE)
  }
  if (
    !inherits(today, "Date") ||
      length(today) != 1L ||
      !is.finite(as.numeric(today))
  ) {
    stop("Ungültiges Bezugsdatum.", call. = FALSE)
  }
  if (is.null(db_pool)) {
    return(trends_empty_annual())
  }
  cutoff <- if (include_current) {
    today
  } else {
    as.Date(paste0(format(today, "%Y"), "-01-01")) - 1L
  }
  # The only interpolated identifier comes from the fixed whitelist above.
  column <- variables$column[match(variable, variables$name)]
  sql <- paste(
    'SELECT substr("MESS_DATUM", 1, 4)::integer AS year,',
    sprintf('       avg(NULLIF("%s", -999)) AS value,', column),
    sprintf('       count(NULLIF("%s", -999)) AS n_days', column),
    'FROM public."Tagesdaten"',
    'WHERE "STATIONS_ID" = $1',
    '  AND ($2::integer = 0 OR substr("MESS_DATUM", 5, 2)::integer = $2::integer)',
    '  AND "MESS_DATUM" <= $3::text',
    'GROUP BY substr("MESS_DATUM", 1, 4)::integer',
    'ORDER BY year',
    sep = "\n"
  )
  data <- trends_query(
    db_pool,
    sql,
    params = list(
      as.integer(station),
      as.integer(month),
      format(cutoff, "%Y%m%d")
    ),
    query = query
  )
  if (!nrow(data)) {
    return(trends_empty_annual())
  }
  data <- data.frame(
    year = as.integer(data$year),
    value = as.numeric(data$value),
    n_days = as.integer(data$n_days)
  )
  period_start <- as.Date(sprintf(
    "%04d-%02d-01",
    data$year,
    if (as.integer(month) == 0L) 1L else as.integer(month)
  ))
  period_end <- if (as.integer(month) == 0L) {
    as.Date(sprintf("%04d-01-01", data$year + 1L)) - 1L
  } else if (as.integer(month) == 12L) {
    as.Date(sprintf("%04d-01-01", data$year + 1L)) - 1L
  } else {
    as.Date(sprintf("%04d-%02d-01", data$year, as.integer(month) + 1L)) - 1L
  }
  expected_days <- as.integer(period_end - period_start) + 1L
  complete <- is.finite(data$value) &
    !is.na(data$n_days) &
    data$n_days == expected_days &
    period_end <= cutoff
  data <- data[complete, , drop = FALSE]
  data$value <- round(data$value, 1)
  data <- data[order(data$year), , drop = FALSE]
  rownames(data) <- NULL
  data
}

trends_regression <- function(data) {
  empty <- data.frame(year = integer(), value = double())
  if (
    !is.data.frame(data) ||
      !all(c("year", "value") %in% names(data)) ||
      !is.numeric(data$year) ||
      !is.numeric(data$value)
  ) {
    return(empty)
  }
  valid <- data[
    is.finite(data$year) & is.finite(data$value),
    c("year", "value"),
    drop = FALSE
  ]
  years <- sort(unique(valid$year))
  if (length(years) < 2L) {
    return(empty)
  }
  fit <- stats::lm(value ~ year, data = valid)
  data.frame(
    year = years,
    value = unname(stats::predict(fit, newdata = data.frame(year = years)))
  )
}
