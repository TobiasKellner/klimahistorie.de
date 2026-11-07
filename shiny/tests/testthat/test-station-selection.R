testthat::test_that("station defaults handle missing and empty station lists", {
  testthat::expect_identical(
    app_functions$station_default_selection(c("Aachen" = "2")),
    "2"
  )
  testthat::expect_identical(
    app_functions$station_default_selection(character()),
    character()
  )
})

testthat::test_that("all tabs default to Erfurt-Weimar from a single query", {
  calls <- 0L
  provider <- function(pool) {
    testthat::expect_identical(pool, "fake")
    calls <<- calls + 1L
    c("Aachen" = "2", "Erfurt-Weimar" = "test-erfurt", "Zugspitze" = "9")
  }
  messages <- list()
  server <- function(input, output, session) {
    session$sendInputMessage <- function(inputId, message) {
      id <- shiny::getDefaultReactiveDomain()$ns(inputId)
      messages[[id]] <<- message
    }
    app_functions$app_server(
      input,
      output,
      session,
      db_pool = "fake",
      stations = provider
    )
  }
  shiny::testServer(
    server,
    {
      session$flushReact()
      testthat::expect_identical(calls, 1L)
      for (id in c(
        "trends",
        "daily_values",
        "year_comparison",
        "daily_history",
        "records",
        "thresholds"
      )) {
        message <- messages[[paste0(id, "-station")]]
        testthat::expect_identical(message$value, "test-erfurt")
        testthat::expect_match(message$options, "Aachen", fixed = TRUE)
        testthat::expect_match(message$options, "Erfurt-Weimar", fixed = TRUE)
        testthat::expect_match(message$options, "Zugspitze", fixed = TRUE)
      }
    }
  )
})
