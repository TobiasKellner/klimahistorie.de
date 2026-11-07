records_data <- function(
  db_pool,
  station,
  record_type,
  query = database_query
) {
  if (
    length(station) != 1L ||
      is.na(station) ||
      !grepl("^[1-9][0-9]*$", as.character(station)) ||
      as.numeric(station) > .Machine$integer.max
  ) {
    stop("Ungültige Stations-ID.", call. = FALSE)
  }
  if (
    length(record_type) != 1L ||
      is.na(record_type) ||
      !record_type %in% c("Maximum", "Minimum")
  ) {
    stop("Ungültiger Rekordtyp.", call. = FALSE)
  }
  columns <- daily_values_metrics()$column
  result <- data.frame(column = columns, date = as.Date(NA), value = NA_real_)
  if (is.null(db_pool)) {
    return(result)
  }
  direction <- if (record_type == "Maximum") "DESC" else "ASC"
  # Each metric is ranked in PostgreSQL; only the nine record rows are transferred.
  statements <- vapply(
    columns,
    function(column) {
      paste(
        sprintf(
          '(SELECT \'%s\' AS column, "MESS_DATUM" AS date, "%s" AS value',
          column,
          column
        ),
        'FROM public."Tagesdaten" WHERE "STATIONS_ID" = $1',
        sprintf(
          'AND "%s" != -999 AND "%s"::double precision > \'-Infinity\'::double precision',
          column,
          column
        ),
        sprintf(
          'AND "%s"::double precision < \'Infinity\'::double precision',
          column
        ),
        sprintf(
          'ORDER BY "%s" %s, "MESS_DATUM" ASC LIMIT 1)',
          column,
          direction
        )
      )
    },
    character(1)
  )
  data <- trends_query(
    db_pool,
    paste(statements, collapse = " UNION ALL "),
    params = list(as.integer(station)),
    query = query
  )
  if (!nrow(data)) {
    return(result)
  }
  dates <- as.Date(data$date, format = "%Y%m%d")
  if (
    anyNA(dates) ||
      any(format(dates, "%Y%m%d") != data$date) ||
      anyDuplicated(data$column) ||
      any(!data$column %in% columns)
  ) {
    stop("Unerwartete Rekorddatenstruktur.", call. = FALSE)
  }
  index <- match(data$column, result$column)
  result$date[index] <- dates
  result$value[index] <- data$value
  result$value[!is.finite(result$value) | result$value == -999] <- NA_real_
  result$date[is.na(result$value)] <- as.Date(NA)
  result
}
