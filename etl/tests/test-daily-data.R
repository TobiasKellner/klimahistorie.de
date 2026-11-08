local({
  source("etl/daily_data.R", local = TRUE)
  fails <- function(expr) inherits(tryCatch(expr, error = identity), "error")
  archive <- "https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily/kl/recent/tageswerte_KL_20278_akt.zip"
  directory <- "ftp://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/"
  stopifnot(
    identical(daily_archive_urls(directory), character()),
    identical(daily_archive_urls(character()), character()),
    identical(daily_archive_urls(c(directory, archive)), archive),
    fails(daily_archive_urls("https://example.org/unexpected.txt"))
  )
  stopifnot(
    identical(limit_daily_station_ids(c(11L, 11L, 44L, 73L)), c(11L, 44L, 73L)),
    identical(limit_daily_station_ids(c(11L, 11L, 44L, 73L), 2), c(11L, 44L)),
    identical(limit_daily_station_ids(c(11L, 44L), 10), c(11L, 44L)),
    is.null(limit_daily_station_ids(NULL, 2)),
    is.null(formals(import_daily_data)$n_stations)
  )
  for (limit in list(
    0,
    -1,
    1.5,
    NA_real_,
    Inf,
    "2",
    TRUE,
    numeric(),
    c(1, 2)
  )) {
    stopifnot(fails(limit_daily_station_ids(11L, limit)))
  }
  header <- paste(names(daily_column_types()), collapse = ";")
  row <- c(
    "1",
    "20260101",
    "-999",
    "-999",
    "2.5",
    "5",
    "0.0",
    "0",
    "1.5",
    "0",
    "3.0",
    "5.0",
    "1000.0",
    "-1.0",
    "80.0",
    "2.0",
    "-3.0",
    "-4.0",
    "eor"
  )
  connection <- textConnection(c(header, paste(row, collapse = ";")))
  historical <- tryCatch(
    read_daily_text(connection),
    finally = close(connection)
  )
  stopifnot(
    ncol(historical) == 19L,
    historical$MESS_DATUM == "20260101",
    historical$QN_3 == -999L,
    historical$FX == -999,
    !anyNA(historical)
  )
  recent <- historical
  recent$TMK <- 7.5
  merged <- merge_daily_data(historical, recent)
  stopifnot(nrow(merged) == 1L, merged$TMK == 7.5)
  calls <- character()
  download <- function(station_id, period, cache_dir) {
    stopifnot(station_id == 1L, identical(cache_dir, "unused-cache"))
    calls <<- c(calls, period)
    switch(period, historical = historical, recent = recent)
  }
  for (period in c("both", "recent", "historical")) {
    calls <- character()
    data <- load_daily_station_data(
      1L,
      "unused-cache",
      period = period,
      download = download
    )
    expected <- if (period == "both") c("historical", "recent") else period
    stopifnot(
      identical(calls, expected),
      identical(data, if (period == "historical") historical else recent)
    )
  }
  calls <- character()
  stopifnot(
    identical(
      load_daily_station_data(1L, "unused-cache", download = download),
      merged
    ),
    identical(calls, c("historical", "recent")),
    fails(import_daily_data(period = "invalid")),
    fails(load_daily_station_data(1L, "unused-cache", period = "invalid"))
  )
  stopifnot(fails(validate_daily_data(rbind(historical, historical))))
  invalid <- historical
  invalid$MESS_DATUM <- "20260230"
  stopifnot(fails(validate_daily_data(invalid)))
  stopifnot(fails(validate_daily_data(historical[, -3L])))
  empty <- historical[FALSE, ]
  stopifnot(
    nrow(merge_daily_data(historical, empty)) == 1L,
    nrow(merge_daily_data(empty, recent)) == 1L
  )
  stopifnot(identical(
    load_daily_station_data(
      1L,
      "unused-cache",
      period = "recent",
      download = function(...) empty
    ),
    empty
  ))
})
