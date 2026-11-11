testthat::test_that("day history selects month and day across years and removes invalid observations", {
  for (i in seq_len(nrow(app_functions$trends_variables()))) {
    variable <- app_functions$trends_variables()[i, ]
    result <- app_functions$daily_history_data(
      "fake",
      "11",
      as.Date("2024-02-29"),
      variable$name,
      query = function(pool, sql, params) {
        testthat::expect_identical(params, list(11L, "0229"))
        testthat::expect_match(
          sql,
          paste0('NULLIF("', variable$column, '", -999)'),
          fixed = TRUE
        )
        data.frame(
          date = c(
            "20200229",
            "20240229",
            "20230229",
            "20160229",
            "20120229",
            "20080229"
          ),
          value = c(-2, 0, 10, -999, NA, Inf)
        )
      }
    )
    testthat::expect_identical(result$year, c(2020L, 2024L))
    testthat::expect_equal(result$value, c(-2, 0))
  }
  testthat::expect_error(
    app_functions$daily_history_data(
      NULL,
      "11 OR 1=1",
      Sys.Date(),
      "Lufttemperatur"
    ),
    "Stations-ID"
  )
  testthat::expect_error(
    app_functions$daily_history_data(NULL, "11", "20240101", "Lufttemperatur"),
    "Datum"
  )
  testthat::expect_error(
    app_functions$daily_history_data(NULL, "11", Sys.Date(), "unknown"),
    "Klimavariable"
  )
  testthat::expect_equal(
    nrow(app_functions$daily_history_data(
      NULL,
      "11",
      Sys.Date(),
      "Lufttemperatur"
    )),
    0L
  )
})

testthat::test_that("history ordering is deterministic and average uses valid daily readings", {
  values <- data.frame(
    date = as.Date(c("2022-01-01", "2020-01-01", "2021-01-01", "2023-01-01")),
    year = c(2022L, 2020L, 2021L, 2023L),
    value = c(4, 4, -2, -999)
  )
  testthat::expect_identical(
    as.character(app_functions$daily_history_order(values)$year),
    c("2020", "2021", "2022")
  )
  testthat::expect_identical(
    as.character(app_functions$daily_history_order(values, TRUE)$year),
    c("2020", "2022", "2021")
  )
  graph <- app_functions$daily_history_plot(
    values,
    "Lufttemperatur",
    "Station",
    TRUE,
    TRUE
  )
  testthat::expect_equal(graph$layers[[2]]$data$yintercept, 2)
  testthat::expect_s3_class(plotly::ggplotly(graph, tooltip = "text"), "plotly")
})

testthat::test_that("history module renders filters, handles empty data and redacts errors", {
  requested <- NULL
  shiny::testServer(
    app_functions$mod_daily_history_server,
    args = list(
      stations = function(pool) c("<Station>" = "11"),
      daily = function(pool, station, date, variable) {
        requested <<- list(station, date, variable)
        if (variable == "Schneehoehe") {
          stop("password=secret")
        }
        if (variable == "Sonnenscheindauer") {
          return(data.frame(value = numeric()))
        }
        data.frame(
          date = as.Date(c("2023-01-01", "2024-01-01")),
          year = c(2023L, 2024L),
          value = c(1, 2)
        )
      }
    ),
    {
      session$setInputs(
        station = "11",
        date = as.Date("2026-01-01"),
        variable = "Lufttemperatur",
        average = FALSE,
        descending = FALSE
      )
      testthat::expect_true(nzchar(output$plot))
      testthat::expect_identical(
        requested,
        list("11", as.Date("2026-01-01"), "Lufttemperatur")
      )
      testthat::expect_match(
        output$description$html,
        "&lt;Station&gt;",
        fixed = TRUE
      )
      session$setInputs(average = TRUE, descending = TRUE)
      testthat::expect_true(nzchar(output$plot))
      session$setInputs(variable = "Schneehoehe")
      testthat::expect_error(
        output$plot,
        "Die Tageshistorie konnte nicht geladen werden",
        fixed = TRUE
      )
      session$setInputs(variable = "Sonnenscheindauer")
      testthat::expect_error(
        output$plot,
        "keine gültigen Messwerte",
        fixed = TRUE
      )
    }
  )
})
