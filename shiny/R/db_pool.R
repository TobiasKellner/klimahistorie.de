database_config <- function(env = Sys.getenv) {
  keys <- c("PGHOST", "PGPORT", "PGDATABASE", "PGUSER", "DB_PASSWORD_FILE")
  values <- setNames(vapply(keys, function(key) env(key, ""), ""), keys)
  if (!any(nzchar(values))) {
    return(NULL)
  }
  if (!all(nzchar(values))) {
    stop(
      "Database configuration is incomplete: set PGHOST, PGPORT, PGDATABASE, PGUSER and DB_PASSWORD_FILE.",
      call. = FALSE
    )
  }
  port <- suppressWarnings(as.numeric(values[["PGPORT"]]))
  if (!is.finite(port) || port != trunc(port) || port < 1 || port > 65535) {
    stop("PGPORT must be an integer between 1 and 65535.", call. = FALSE)
  }
  sslmode <- env("PGSSLMODE", "prefer")
  if (
    !sslmode %in%
      c("disable", "allow", "prefer", "require", "verify-ca", "verify-full")
  ) {
    stop("Invalid PGSSLMODE.", call. = FALSE)
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

database_password <- function(path) {
  password <- tryCatch(readLines(path, warn = FALSE), error = function(e) NULL)
  if (length(password) != 1L || !nzchar(password)) {
    stop(
      "Database password file must be readable and contain one nonempty line.",
      call. = FALSE
    )
  }
  password
}

database_pool_create <- function(
  config = database_config(),
  create = pool::dbPool,
  driver = RPostgres::Postgres,
  read_password = database_password
) {
  if (is.null(config)) {
    return(NULL)
  }
  password <- read_password(config$password_file)
  tryCatch(
    create(
      drv = driver(),
      host = config$host,
      port = config$port,
      dbname = config$dbname,
      user = config$user,
      password = password,
      sslmode = config$sslmode,
      connect_timeout = 5,
      application_name = "klimahistorie-shiny",
      minSize = 1,
      maxSize = 5,
      idleTimeout = 60,
      validationInterval = 0,
      validateQuery = "SELECT 1",
      onCreate = function(connection) {
        DBI::dbExecute(connection, "SET default_transaction_read_only = on")
        DBI::dbExecute(connection, "SET statement_timeout = '15s'")
      }
    ),
    error = function(e) {
      stop(
        "Cannot establish the configured PostgreSQL connection. Check database availability and credentials.",
        call. = FALSE
      )
    }
  )
}

database_lifecycle <- function(
  create = database_pool_create,
  close = pool::poolClose,
  register_stop = shiny::onStop
) {
  connection_pool <- NULL
  stop_pool <- function() {
    if (!is.null(connection_pool)) {
      previous <- connection_pool
      connection_pool <<- NULL
      close(previous)
    }
  }
  list(
    start = function() {
      if (is.null(connection_pool)) {
        connection_pool <<- create()
        if (!is.null(connection_pool)) register_stop(stop_pool, session = NULL)
      }
      invisible(NULL)
    },
    get = function() connection_pool,
    stop = stop_pool
  )
}

database_query <- function(db_pool, sql, params = NULL) {
  if (is.null(db_pool)) {
    stop("No database is configured for this app.", call. = FALSE)
  }
  if (is.null(params)) {
    DBI::dbGetQuery(db_pool, sql)
  } else {
    DBI::dbGetQuery(db_pool, sql, params = params)
  }
}
