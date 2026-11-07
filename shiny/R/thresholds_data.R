thresholds_settings <- function(variable) {
  variables <- trends_variables()
  index <- match(variable, variables$name)
  if (length(index) != 1L || is.na(index)) {
    stop("Ungültige Klimavariable.", call. = FALSE)
  }
  list(
    column = variables$column[[index]],
    label = c(
      "Lufttemperatur",
      "Schneehöhe",
      "Sonnenscheindauer",
      "Niederschlagshöhe"
    )[[index]],
    unit = c("°C", "cm", "h", "mm")[[index]],
    min = c(-30, 0, 0, 0)[[index]],
    max = c(40, 100, 24, 50)[[index]],
    default = c(10, 10, 5, 5)[[index]]
  )
}

thresholds_empty_annual <- function() {
  data.frame(year = integer(), n_threshold = integer(), n_days = integer())
}

thresholds_annual_data <- function(
  db_pool,
  station,
  variable,
  threshold,
  direction = "over",
  include_current = FALSE,
  today = Sys.Date(),
  query = database_query
) {
  if (
    length(station) != 1L ||
      is.object(station) ||
      is.na(station) ||
      !grepl("^[1-9][0-9]*$", as.character(station)) ||
      as.numeric(station) > .Machine$integer.max
  ) {
    stop("Ungültige Stations-ID.", call. = FALSE)
  }
  settings <- thresholds_settings(variable)
  if (
    !is.numeric(threshold) ||
      length(threshold) != 1L ||
      !is.finite(threshold) ||
      threshold < settings$min ||
      threshold > settings$max
  ) {
    stop("Ungültiger Schwellenwert.", call. = FALSE)
  }
  if (
    length(direction) != 1L ||
      is.na(direction) ||
      !direction %in% c("over", "under")
  ) {
    stop("Ungültige Schwellenrichtung.", call. = FALSE)
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
    return(thresholds_empty_annual())
  }
  cutoff <- if (include_current) {
    today
  } else {
    as.Date(paste0(format(today, "%Y"), "-01-01")) - 1L
  }
  # Only whitelisted identifiers and operators are interpolated; values are bound.
  column <- sprintf('NULLIF("%s", -999)', settings$column)
  operator <- if (direction == "over") ">=" else "<="
  sql <- paste(
    'SELECT substr("MESS_DATUM", 1, 4)::integer AS year,',
    sprintf(
      '       count(*) FILTER (WHERE %s %s $2::numeric) AS n_threshold,',
      column,
      operator
    ),
    sprintf('       count(%s) AS n_days', column),
    'FROM public."Tagesdaten"',
    'WHERE "STATIONS_ID" = $1 AND "MESS_DATUM" <= $3::text',
    'GROUP BY substr("MESS_DATUM", 1, 4)::integer',
    'ORDER BY year',
    sep = "\n"
  )
  data <- trends_query(
    db_pool,
    sql,
    params = list(
      as.integer(station),
      as.numeric(threshold),
      format(cutoff, "%Y%m%d")
    ),
    query = query
  )
  if (!nrow(data)) {
    return(thresholds_empty_annual())
  }
  data <- data.frame(
    year = as.integer(data$year),
    n_threshold = as.integer(data$n_threshold),
    n_days = as.integer(data$n_days)
  )
  data <- data[!is.na(data$n_days) & data$n_days > 0L, , drop = FALSE]
  data <- data[order(data$year), , drop = FALSE]
  rownames(data) <- NULL
  data
}
