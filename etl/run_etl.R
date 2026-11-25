args <- commandArgs(trailingOnly = TRUE)

run_station <- Sys.getenv("ETL_RUN_STATION", "true")
run_daily <- Sys.getenv("ETL_RUN_DAILY", "true")
daily_period <- Sys.getenv("ETL_DAILY_PERIOD", "both")
n_stations_raw <- Sys.getenv("ETL_N_STATIONS", "")
keep_archives_raw <- Sys.getenv("ETL_KEEP_ARCHIVES", "false")

if (length(args)) {
  stop(
    "run_etl.R erwartet keine Positionsargumente. Steuerung über Umgebungsvariablen.",
    call. = FALSE
  )
}

as_flag <- function(x, name) {
  x <- tolower(trimws(x))
  if (!x %in% c("true", "false")) {
    stop(sprintf("%s muss 'true' oder 'false' sein.", name), call. = FALSE)
  }
  identical(x, "true")
}

parse_n_stations <- function(x) {
  if (!nzchar(trimws(x))) {
    return(NULL)
  }
  n <- suppressWarnings(as.numeric(x))
  if (!is.finite(n) || n < 1 || n != trunc(n)) {
    stop(
      "ETL_N_STATIONS muss leer oder eine positive ganze Zahl sein.",
      call. = FALSE
    )
  }
  as.integer(n)
}

run_station <- as_flag(run_station, "ETL_RUN_STATION")
run_daily <- as_flag(run_daily, "ETL_RUN_DAILY")
keep_archives <- as_flag(keep_archives_raw, "ETL_KEEP_ARCHIVES")
n_stations <- parse_n_stations(n_stations_raw)

if (!daily_period %in% c("both", "recent", "historical")) {
  stop(
    "ETL_DAILY_PERIOD muss 'both', 'recent' oder 'historical' sein.",
    call. = FALSE
  )
}

if (!run_station && !run_daily) {
  stop(
    "Mindestens einer der Schritte muss aktiviert sein (ETL_RUN_STATION/ETL_RUN_DAILY).",
    call. = FALSE
  )
}

if (run_station) {
  source("etl/Import_station_table.R", local = TRUE)
}

if (run_daily) {
  source("etl/db_connection.R", local = TRUE)
  source("etl/daily_data.R", local = TRUE)
  import_daily_data(
    n_stations = n_stations,
    period = daily_period,
    keep_archives = keep_archives
  )
}
