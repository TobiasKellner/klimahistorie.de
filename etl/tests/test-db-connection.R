local({
  source("etl/db_connection.R", local = TRUE)
  values <- c(
    PGHOST = "127.0.0.1",
    PGPORT = "5432",
    PGDATABASE = "klimahistorie",
    PGUSER = "climate_etl",
    DB_PASSWORD_FILE = "unused-test-path"
  )
  env <- function(key, default = "") {
    if (key %in% names(values)) unname(values[[key]]) else default
  }
  fails <- function(expr) inherits(tryCatch(expr, error = identity), "error")
  config <- etl_database_config(env)
  stopifnot(config$port == 5432L, config$user == "climate_etl")
  stopifnot(fails(etl_database_config(function(key, default = "") default)))
  for (port in c("0", "65536", "3.5", "invalid")) {
    values[["PGPORT"]] <- port
    stopifnot(fails(etl_database_config(env)))
  }
  values[["PGPORT"]] <- "5432"
  stopifnot(fails(etl_database_config(function(key, default = "") {
    if (key == "PGSSLMODE") "invalid" else env(key, default)
  })))
  result <- db_connection(
    config = config,
    driver = function() "test-driver",
    read_password = function(path) "synthetic-test-password",
    connect = function(...) list(...)
  )
  stopifnot(
    result$dbname == "klimahistorie",
    result$application_name == "klimahistorie-etl"
  )
  error <- tryCatch(
    db_connection(
      config = config,
      driver = function() NULL,
      read_password = function(path) "synthetic-test-password",
      connect = function(...) stop("sensitive-driver-details")
    ),
    error = identity
  )
  stopifnot(
    inherits(error, "error"),
    !grepl("sensitive-driver-details", conditionMessage(error))
  )
})
