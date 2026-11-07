testthat::test_that("overview renders values, quality and station/year changes", {
  fixture <- data.frame(
    year = c(2023L, 2024L),
    temperature = c(10, 11),
    frost = c(50, 40),
    heat = c(12, 18),
    rain = c(600, NA_real_),
    n_temperature = c(365L, 366L),
    n_frost = c(365L, 366L),
    n_heat = c(365L, 366L),
    n_rain = c(365L, 300L),
    expected = c(365L, 366L),
    last_date = as.Date(c("2023-12-31", "2024-12-31"))
  )
  calls <- list()
  shiny::testServer(
    app_functions$mod_overview_server,
    args = list(
      db_pool = "fake",
      stations = function(pool) c("Erfurt-Weimar" = "2", "Aachen" = "3"),
      annual = function(pool, station) {
        calls[[length(calls) + 1L]] <<- station
        fixture
      }
    ),
    {
      session$setInputs(station = "2")
      session$flushReact()
      session$setInputs(year = "2024")
      testthat::expect_match(
        output$headline$html,
        "Erfurt-Weimar",
        fixed = TRUE
      )
      testthat::expect_match(output$values$html, "11,0", fixed = TRUE)
      testthat::expect_match(
        output$values$html,
        "Nicht verfügbar",
        fixed = TRUE
      )
      testthat::expect_match(output$quality$html, "300 von 366", fixed = TRUE)
      testthat::expect_match(output$quality$html, "<progress", fixed = TRUE)
      testthat::expect_match(output$quality$html, "31.12.2024", fixed = TRUE)
      session$setInputs(year = "2023")
      testthat::expect_match(output$values$html, "600,0", fixed = TRUE)
      testthat::expect_length(calls, 1L)
      session$setInputs(station = "3")
      session$flushReact()
      session$setInputs(year = "2023")
      testthat::expect_match(output$headline$html, "Aachen", fixed = TRUE)
      testthat::expect_identical(calls, list("2", "3"))
    }
  )
})

testthat::test_that("overview handles empty data and provider errors safely", {
  for (fail in c(FALSE, TRUE)) {
    provider <- local({
      should_fail <- fail
      function(pool, station) {
        if (should_fail) {
          stop("private database details")
        }
        app_functions$overview_empty_annual()
      }
    })
    shiny::testServer(
      app_functions$mod_overview_server,
      args = list(
        stations = function(pool) c("Erfurt-Weimar" = "2"),
        annual = provider
      ),
      {
        session$setInputs(station = "2")
        session$flushReact()
        session$setInputs(year = "2024")
        testthat::expect_error(
          output$values,
          if (fail) "Klimadaten konnten nicht" else "keine Jahresdaten"
        )
      }
    )
  }
})
