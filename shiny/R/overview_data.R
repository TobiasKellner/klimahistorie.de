overview_metrics <- function() {
  data.frame(
    key = c(
      "temperature",
      "frost",
      "heat",
      "rain",
      "max_temperature",
      "min_temperature",
      "sunshine",
      "snow"
    ),
    label = c(
      "Jahresmitteltemperatur",
      "Frosttage",
      "Heiße Tage",
      "Niederschlagssumme",
      "Maximaltemperatur",
      "Minimaltemperatur",
      "Sonnenscheindauer",
      "Tage mit Schneedecke"
    ),
    unit = c("°C", "Tage", "Tage", "mm", "°C", "°C", "Stunden", "Tage"),
    icon = c(
      "temperature-half",
      "icicles",
      "fire",
      "umbrella",
      "temperature-full",
      "temperature-empty",
      "sun",
      "snowflake"
    ),
    theme = c(
      "orange",
      "blue",
      "red",
      "green",
      "pink",
      "purple",
      "yellow",
      "teal"
    ),
    stringsAsFactors = FALSE
  )
}

overview_empty_annual <- function() {
  data.frame(
    year = integer(),
    temperature = double(),
    frost = double(),
    heat = double(),
    rain = double(),
    max_temperature = double(),
    min_temperature = double(),
    sunshine = double(),
    snow = double(),
    n_temperature = integer(),
    n_frost = integer(),
    n_heat = integer(),
    n_rain = integer(),
    n_max_temperature = integer(),
    n_min_temperature = integer(),
    n_sunshine = integer(),
    n_snow = integer(),
    expected = integer(),
    last_date = as.Date(character()),
    max_temperature_date = as.Date(character()),
    min_temperature_date = as.Date(character())
  )
}

overview_annual_data <- function(db_pool, station, query = database_query) {
  if (
    length(station) != 1L ||
      is.na(station) ||
      !grepl("^[1-9][0-9]*$", as.character(station)) ||
      as.numeric(station) > .Machine$integer.max
  ) {
    stop("Ungültige Stations-ID.", call. = FALSE)
  }
  empty <- overview_empty_annual()
  if (is.null(db_pool)) {
    return(empty)
  }

  current_year <- as.integer(format(Sys.Date(), "%Y"))
  sql <- paste(
    'SELECT substr("MESS_DATUM", 1, 4)::integer AS year,',
    '       avg(NULLIF("TMK", -999)) AS temperature,',
    '       count(NULLIF("TMK", -999)) AS n_temperature,',
    '       count(NULLIF("TNK", -999)) FILTER (WHERE NULLIF("TNK", -999) < 0) AS frost,',
    '       count(NULLIF("TNK", -999)) AS n_frost,',
    '       count(NULLIF("TXK", -999)) FILTER (WHERE NULLIF("TXK", -999) >= 30) AS heat,',
    '       count(NULLIF("TXK", -999)) AS n_heat,',
    '       sum(NULLIF("RSK", -999)) AS rain,',
    '       count(NULLIF("RSK", -999)) AS n_rain,',
    '       max(NULLIF("TXK", -999)) AS max_temperature,',
    '       count(NULLIF("TXK", -999)) AS n_max_temperature,',
    '       min(NULLIF("TNK", -999)) AS min_temperature,',
    '       count(NULLIF("TNK", -999)) AS n_min_temperature,',
    '       sum(NULLIF("SDK", -999)) AS sunshine,',
    '       count(NULLIF("SDK", -999)) AS n_sunshine,',
    '       count(NULLIF("SHK_TAG", -999)) FILTER (WHERE NULLIF("SHK_TAG", -999) > 0) AS snow,',
    '       count(NULLIF("SHK_TAG", -999)) AS n_snow,',
    '       (array_agg("MESS_DATUM" ORDER BY NULLIF("TXK", -999) DESC NULLS LAST, "MESS_DATUM") FILTER (WHERE NULLIF("TXK", -999) IS NOT NULL))[1] AS max_temperature_date,',
    '       (array_agg("MESS_DATUM" ORDER BY NULLIF("TNK", -999) ASC NULLS LAST, "MESS_DATUM") FILTER (WHERE NULLIF("TNK", -999) IS NOT NULL))[1] AS min_temperature_date,',
    '       max("MESS_DATUM") AS last_date',
    'FROM public."Tagesdaten"',
    'WHERE "STATIONS_ID" = $1',
    '  AND substr("MESS_DATUM", 1, 4)::integer <= $2::integer',
    'GROUP BY substr("MESS_DATUM", 1, 4)::integer',
    'ORDER BY year',
    sep = "\n"
  )
  data <- trends_query(
    db_pool,
    sql,
    params = list(as.integer(station), current_year),
    query = query
  )
  if (!nrow(data)) {
    return(empty)
  }

  required <- names(empty)[names(empty) != "expected"]
  if (!all(required %in% names(data))) {
    stop("Unerwartete Jahresdatenstruktur.", call. = FALSE)
  }
  parse_date <- function(x) {
    parsed <- as.Date(as.character(x), format = "%Y%m%d")
    # DBI drivers may already return ISO Date strings rather than YYYYMMDD strings.
    needs_iso_parse <- is.na(parsed) & !is.na(x)
    parsed[needs_iso_parse] <- as.Date(as.character(x[needs_iso_parse]))
    parsed
  }
  result <- data.frame(
    year = as.integer(data$year),
    temperature = as.numeric(data$temperature),
    frost = as.numeric(data$frost),
    heat = as.numeric(data$heat),
    rain = as.numeric(data$rain),
    max_temperature = as.numeric(data$max_temperature),
    min_temperature = as.numeric(data$min_temperature),
    sunshine = as.numeric(data$sunshine),
    snow = as.numeric(data$snow),
    n_temperature = as.integer(data$n_temperature),
    n_frost = as.integer(data$n_frost),
    n_heat = as.integer(data$n_heat),
    n_rain = as.integer(data$n_rain),
    n_max_temperature = as.integer(data$n_max_temperature),
    n_min_temperature = as.integer(data$n_min_temperature),
    n_sunshine = as.integer(data$n_sunshine),
    n_snow = as.integer(data$n_snow),
    expected = integer(nrow(data)),
    last_date = parse_date(data$last_date),
    max_temperature_date = parse_date(data$max_temperature_date),
    min_temperature_date = parse_date(data$min_temperature_date)
  )
  year_start <- as.Date(sprintf("%04d-01-01", result$year))
  result$expected <- as.integer(
    as.Date(sprintf("%04d-01-01", result$year + 1L)) - year_start
  )
  for (key in overview_metrics()$key) {
    count <- result[[paste0("n_", key)]]
    incomplete <- is.na(count) |
      count != result$expected |
      result$year == current_year
    result[[key]][incomplete] <- NA_real_
  }
  for (key in c("max_temperature", "min_temperature")) {
    result[[paste0(key, "_date")]][is.na(result[[key]])] <- as.Date(NA)
  }
  result <- result[order(result$year), , drop = FALSE]
  rownames(result) <- NULL
  result
}

overview_reference <- function(data, key) {
  if (
    !is.data.frame(data) ||
      !is.character(key) ||
      length(key) != 1L ||
      is.na(key) ||
      !key %in% overview_metrics()$key ||
      !all(c("year", key) %in% names(data))
  ) {
    return(NA_real_)
  }
  if (key %in% c("max_temperature", "min_temperature")) {
    return(NA_real_)
  }
  reference <- data[
    data$year %in% 1991:2020 & is.finite(data[[key]]),
    ,
    drop = FALSE
  ]
  if (
    nrow(reference) != 30L ||
      length(unique(reference$year)) != 30L ||
      !setequal(reference$year, 1991:2020)
  ) {
    return(NA_real_)
  }
  mean(reference[[key]])
}

overview_default_year <- function(data, today = Sys.Date()) {
  if (!is.data.frame(data) || !"year" %in% names(data) || !nrow(data)) {
    return(character())
  }
  years <- suppressWarnings(as.integer(data$year))
  valid_years <- years[!is.na(years)]
  if (!length(valid_years)) {
    return(character())
  }
  keys <- intersect(overview_metrics()$key, names(data))
  closed <- rep(FALSE, nrow(data))
  if (length(keys)) {
    closed <- years < as.integer(format(today, "%Y")) &
      Reduce(`|`, lapply(keys, function(key) !is.na(data[[key]])))
  }
  if (any(closed, na.rm = TRUE)) {
    return(as.character(max(years[closed], na.rm = TRUE)))
  }
  as.character(max(valid_years))
}
