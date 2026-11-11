etl_database_config <- function(env = Sys.getenv) {
  keys <- c("PGHOST", "PGPORT", "PGDATABASE", "PGUSER", "DB_PASSWORD_FILE")
  values <- setNames(vapply(keys, function(key) env(key, ""), ""), keys)
  if (!all(nzchar(values))) {
    stop(
      "Für den ETL-Zugang PGHOST, PGPORT, PGDATABASE, PGUSER und DB_PASSWORD_FILE setzen.",
      call. = FALSE
    )
  }
  port <- suppressWarnings(as.numeric(values[["PGPORT"]]))
  if (!is.finite(port) || port != trunc(port) || port < 1 || port > 65535) {
    stop(
      "PGPORT muss eine ganze Zahl zwischen 1 und 65535 sein.",
      call. = FALSE
    )
  }
  sslmode <- env("PGSSLMODE", "prefer")
  if (
    !sslmode %in%
      c("disable", "allow", "prefer", "require", "verify-ca", "verify-full")
  ) {
    stop("Ungültiger PGSSLMODE.", call. = FALSE)
  }
  list(
    host = values[["PGHOST"]],
    port = as.integer(port),
    dbname = values[["PGDATABASE"]],
    user = values[["PGUSER"]],
    password_file = values[["DB_PASSWORD_FILE"]],
    sslmode = sslmode
  )
}

etl_database_password <- function(path) {
  password <- tryCatch(readLines(path, warn = FALSE), error = function(e) NULL)
  if (length(password) != 1L || !nzchar(password)) {
    stop(
      "Die Passwortdatei muss lesbar sein und genau eine nichtleere Zeile enthalten.",
      call. = FALSE
    )
  }
  password
}

db_connection <- function(
  config = etl_database_config(),
  connect = DBI::dbConnect,
  driver = RPostgres::Postgres,
  read_password = etl_database_password
) {
  password <- read_password(config$password_file)
  tryCatch(
    connect(
      drv = driver(),
      host = config$host,
      port = config$port,
      dbname = config$dbname,
      user = config$user,
      password = password,
      sslmode = config$sslmode,
      connect_timeout = 5,
      application_name = "klimahistorie-etl"
    ),
    error = function(e) {
      # Driver errors may contain sensitive connection details.
      stop(
        "ETL-Verbindung fehlgeschlagen. Erreichbarkeit und Zugangsdaten prüfen.",
        call. = FALSE
      )
    }
  )
}
