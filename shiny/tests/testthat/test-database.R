testthat::test_that("database configuration is optional but cannot be partial", {
  env <- function(key, default = "") default
  testthat::expect_null(app_functions$database_config(env))
  testthat::expect_null(app_functions$database_pool_create(
    NULL,
    create = function(...) stop("Unexpected call")
  ))
  testthat::expect_error(
    app_functions$database_config(function(key, default = "") {
      if (key == "PGHOST") "postgres" else default
    }),
    "incomplete"
  )
  values <- c(
    PGHOST = "postgres",
    PGPORT = "5432",
    PGDATABASE = "klimahistorie",
    PGUSER = "climate_reader",
    DB_PASSWORD_FILE = "unused"
  )
  env <- function(key, default = "") {
    if (key %in% names(values)) values[[key]] else default
  }
  testthat::expect_identical(app_functions$database_config(env)$port, 5432L)
  values[["PGPORT"]] <- "invalid"
  testthat::expect_error(app_functions$database_config(env), "PGPORT")
})

testthat::test_that("pool construction uses constrained connections and safe errors", {
  testthat::expect_error(
    suppressWarnings(app_functions$database_password(file.path(
      app_dir,
      "does-not-exist"
    ))),
    "password file must be readable"
  )
  config <- list(
    host = "postgres",
    port = 5432L,
    dbname = "klimahistorie",
    user = "climate_reader",
    password_file = "unused",
    sslmode = "prefer"
  )
  args <- app_functions$database_pool_create(
    config,
    create = function(...) list(...),
    driver = function() "driver",
    read_password = function(path) "test-password"
  )
  testthat::expect_identical(args$user, "climate_reader")
  testthat::expect_equal(args$maxSize, 5)
  testthat::expect_equal(args$validationInterval, 0)
  testthat::expect_true(is.function(args$onCreate))
  testthat::expect_error(
    app_functions$database_pool_create(
      config,
      create = function(...) stop("sensitive detail"),
      driver = function() "driver",
      read_password = function(path) "test-password"
    ),
    "^Cannot establish the configured PostgreSQL connection"
  )
})

testthat::test_that("one pool is shared and closed at application shutdown only", {
  created <- 0L
  closed <- 0L
  callback <- NULL
  shared <- new.env()
  lifecycle <- app_functions$database_lifecycle(
    create = function() {
      created <<- created + 1L
      shared
    },
    close = function(value) {
      testthat::expect_identical(value, shared)
      closed <<- closed + 1L
    },
    register_stop = function(fun, session) {
      testthat::expect_null(session)
      callback <<- fun
    }
  )
  lifecycle$start()
  lifecycle$start()
  testthat::expect_equal(created, 1L)
  server <- function(input, output, session) {
    app_functions$app_server(input, output, session, lifecycle$get())
  }
  for (i in 1:2) {
    shiny::testServer(server, {
      testthat::expect_identical(session$userData$db_pool, shared)
    })
  }
  testthat::expect_equal(closed, 0L)
  callback()
  lifecycle$stop()
  testthat::expect_equal(closed, 1L)
  testthat::expect_null(lifecycle$get())
})
