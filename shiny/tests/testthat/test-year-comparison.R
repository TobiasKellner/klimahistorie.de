testthat::test_that("comparison years and raw daily data preserve calendar alignment", {
  testthat::expect_identical(
    app_functions$year_comparison_years("2024, 2023,2024"),
    c(2024L, 2023L)
  )
  testthat::expect_error(
    app_functions$year_comparison_years("2024;DROP"),
    "vierstellige"
  )
  testthat::expect_error(
    app_functions$year_comparison_years(""),
    "vierstellige"
  )
  values <- app_functions$year_comparison_data(
    "fake",
    "11",
    "Lufttemperatur",
    "2",
    query = function(pool, sql, params) {
      testthat::expect_identical(params, list(11L, "02"))
      testthat::expect_match(sql, 'NULLIF("TMK", -999)', fixed = TRUE)
      testthat::expect_match(
        sql,
        'substring("MESS_DATUM", 5, 2) = $2::text',
        fixed = TRUE
      )
      data.frame(
        date = c("20230228", "20240228", "20240229", "20240301", "20240230"),
        value = c(-2, 0, 3, -999, 8)
      )
    }
  )
  testthat::expect_equal(nrow(values), 4L)
  testthat::expect_equal(values$calendar_date[3], as.Date("2000-02-29"))
  testthat::expect_true(is.na(values$value[4]))
  testthat::expect_equal(
    app_functions$year_comparison_mean(values)$value,
    c(-1, 3)
  )
  testthat::expect_error(
    app_functions$year_comparison_data(NULL, "11 OR 1=1", "Lufttemperatur"),
    "Stations-ID"
  )
  testthat::expect_error(
    app_functions$year_comparison_data(NULL, "11", "unknown"),
    "Klimavariable"
  )
  testthat::expect_error(
    app_functions$year_comparison_data(NULL, "11", "Lufttemperatur", 13),
    "Monat"
  )
  testthat::expect_equal(
    nrow(app_functions$year_comparison_data(NULL, "11", "Lufttemperatur")),
    0L
  )
  for (type in c("Linie", "Punkte", "Balken")) {
    graph <- app_functions$year_comparison_plot(
      values,
      c(2024L, 2023L),
      type,
      "Lufttemperatur",
      TRUE
    )
    testthat::expect_equal(length(graph$layers), 3L)
    testthat::expect_s3_class(
      plotly::ggplotly(graph, tooltip = "text"),
      "plotly"
    )
  }
})

testthat::test_that("comparison module renders all modes and validates years", {
  calls <- list()
  shiny::testServer(
    app_functions$mod_year_comparison_server,
    args = list(
      stations = function(pool) c("Teststation" = "11"),
      daily = function(pool, station, variable, month) {
        calls[[length(calls) + 1L]] <<- list(station, variable, month)
        data.frame(
          date = as.Date(c(
            "2023-01-01",
            "2023-01-02",
            "2024-01-01",
            "2024-01-02"
          )),
          year = c(2023L, 2023L, 2024L, 2024L),
          calendar_date = as.Date(c(
            "2000-01-01",
            "2000-01-02",
            "2000-01-01",
            "2000-01-02"
          )),
          value = c(1, 2, 3, 4)
        )
      }
    ),
    {
      session$setInputs(
        station = "11",
        variable = "Lufttemperatur",
        month = "0",
        years = "2024,2023",
        type = "Linie",
        average = FALSE
      )
      testthat::expect_true(nzchar(output$plot))
      testthat::expect_match(
        output$description$html,
        "Teststation",
        fixed = TRUE
      )
      for (type in c("Punkte", "Balken")) {
        session$setInputs(type = type, average = TRUE, month = "1")
        testthat::expect_true(nzchar(output$plot))
      }
      testthat::expect_identical(
        tail(calls, 1)[[1]],
        list("11", "Lufttemperatur", "1")
      )
      session$setInputs(years = "invalid")
      testthat::expect_error(output$plot, "vierstellige")
      session$setInputs(years = "1999")
      testthat::expect_error(output$plot, "Vergleichsjahre")
    }
  )
})

testthat::test_that("comparison provider errors are neutral", {
  shiny::testServer(
    app_functions$mod_year_comparison_server,
    args = list(
      stations = function(pool) c("Teststation" = "11"),
      daily = function(...) stop("password=secret")
    ),
    {
      session$setInputs(
        station = "11",
        variable = "Lufttemperatur",
        month = "0",
        years = "2024",
        type = "Linie"
      )
      testthat::expect_error(
        output$plot,
        "Die Vergleichsdaten konnten nicht geladen werden",
        fixed = TRUE
      )
    }
  )
})
