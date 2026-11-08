testthat::test_that("data quality is collapsed initially", {
  html <- htmltools::renderTags(app_functions$mod_overview_ui("overview"))$html
  testthat::expect_match(html, 'id="overview-quality_details"', fixed = TRUE)
  testthat::expect_match(html, 'id="overview-show_map"', fixed = TRUE)
  testthat::expect_match(html, 'aria-expanded="false"', fixed = TRUE)
  testthat::expect_false(grepl(
    'accordion-collapse collapse show',
    html,
    fixed = TRUE
  ))
})

testthat::test_that("overview renders values, quality and station/year changes", {
  fixture <- data.frame(
    year = c(2023L, 2024L),
    temperature = c(10, 11),
    frost = c(50, 40),
    heat = c(12, 18),
    rain = c(600, NA_real_),
    max_temperature = c(33, 35),
    min_temperature = c(-12, -10),
    sunshine = c(1700, 1800),
    snow = c(15, 20),
    n_temperature = c(365L, 366L),
    n_frost = c(365L, 366L),
    n_heat = c(365L, 366L),
    n_rain = c(365L, 300L),
    n_max_temperature = c(365L, 366L),
    n_min_temperature = c(365L, 366L),
    n_sunshine = c(365L, 366L),
    n_snow = c(365L, 366L),
    max_temperature_date = as.Date(c("2023-07-10", "2024-08-12")),
    min_temperature_date = as.Date(c("2023-01-15", "2024-01-20")),
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
        output$headline$html,
        "Acht Kennzahlen aus dem Kalenderjahr",
        fixed = TRUE
      )
      testthat::expect_false(grepl(
        "DEIN LOKALER KLIMARÜCKBLICK",
        output$headline$html,
        fixed = TRUE
      ))
      testthat::expect_match(
        output$values$html,
        "Nicht verfügbar",
        fixed = TRUE
      )
      testthat::expect_match(output$quality$html, "300 von 366", fixed = TRUE)
      testthat::expect_match(
        output$values$html,
        "300 von 366 gültigen Tageswerten",
        fixed = TRUE
      )
      testthat::expect_match(output$quality$html, "<progress", fixed = TRUE)
      testthat::expect_match(output$quality$html, "31.12.2024", fixed = TRUE)
      testthat::expect_match(output$values$html, "12.08.2024", fixed = TRUE)
      testthat::expect_match(output$values$html, "20.01.2024", fixed = TRUE)
      testthat::expect_match(
        output$values$html,
        "1.800,0 Stunden",
        fixed = TRUE
      )
      testthat::expect_match(output$values$html, "20 Tage", fixed = TRUE)
      testthat::expect_match(
        output$quality$html,
        "Tage mit Schneedecke",
        fixed = TRUE
      )
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

testthat::test_that("overview map button opens the selected station modal on click", {
  calls <- list()
  locations <- character()
  shiny::testServer(
    app_functions$mod_overview_server,
    args = list(
      db_pool = "fake",
      stations = function(pool) c("Erfurt-Weimar" = "2", "Aachen" = "3"),
      location = function(pool, station) {
        testthat::expect_identical(pool, "fake")
        locations <<- c(locations, station)
        NULL
      },
      show = function(ui) calls[[length(calls) + 1L]] <<- ui
    ),
    {
      session$flushReact()
      testthat::expect_length(calls, 0L)
      session$setInputs(station = "2", show_map = 1)
      testthat::expect_length(calls, 1L)
      html <- htmltools::renderTags(calls[[1L]])$html
      testthat::expect_match(html, "Wetterstation: Erfurt-Weimar", fixed = TRUE)
      testthat::expect_match(html, "Stationskarte", fixed = TRUE)
      session$setInputs(station = "3", show_map = 2)
      testthat::expect_identical(locations, c("2", "3"))
      testthat::expect_match(
        htmltools::renderTags(calls[[2L]])$html,
        "Wetterstation: Aachen",
        fixed = TRUE
      )
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
