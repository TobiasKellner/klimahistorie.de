testthat::test_that("threshold ranges and defaults match the old app", {
  variables <- app_functions$trends_variables()
  settings <- lapply(variables$name, app_functions$thresholds_settings)
  testthat::expect_equal(
    vapply(settings, `[[`, numeric(1), "min"),
    c(-30, 0, 0, 0)
  )
  testthat::expect_equal(
    vapply(settings, `[[`, numeric(1), "max"),
    c(40, 100, 24, 50)
  )
  testthat::expect_equal(
    vapply(settings, `[[`, numeric(1), "default"),
    c(10, 10, 5, 5)
  )
})

testthat::test_that("annual threshold queries bind values and count inclusive comparisons", {
  variables <- app_functions$trends_variables()
  for (i in seq_len(nrow(variables))) {
    for (direction in c("over", "under")) {
      result <- app_functions$thresholds_annual_data(
        "mock",
        "42",
        variables$name[[i]],
        0,
        direction,
        today = as.Date("2026-11-07"),
        query = function(pool, sql, params) {
          testthat::expect_identical(params, list(42L, 0, "20251231"))
          operator <- if (direction == "over") ">=" else "<="
          testthat::expect_match(
            sql,
            sprintf(
              'NULLIF("%s", -999) %s $2::numeric',
              variables$column[[i]],
              operator
            ),
            fixed = TRUE
          )
          testthat::expect_match(sql, 'count(NULLIF(', fixed = TRUE)
          testthat::expect_match(sql, '"STATIONS_ID" = $1', fixed = TRUE)
          testthat::expect_match(sql, '"MESS_DATUM" <= $3::text', fixed = TRUE)
          data.frame(
            year = c(2021, 2020, 2019),
            n_threshold = c(0, 10, 0),
            n_days = c(200, 366, 0)
          )
        }
      )
      testthat::expect_identical(
        result,
        data.frame(
          year = 2020:2021,
          n_threshold = c(10L, 0L),
          n_days = c(366L, 200L)
        )
      )
    }
  }
  app_functions$thresholds_annual_data(
    "mock",
    1,
    "Lufttemperatur",
    -10,
    include_current = TRUE,
    today = as.Date("2026-01-01"),
    query = function(pool, sql, params) {
      testthat::expect_identical(params, list(1L, -10, "20260101"))
      data.frame()
    }
  )
})

testthat::test_that("invalid threshold selections never reach the database", {
  run <- function(...) {
    do.call(
      app_functions$thresholds_annual_data,
      modifyList(
        list(
          db_pool = "mock",
          station = 1,
          variable = "Lufttemperatur",
          threshold = 10,
          query = function(...) stop("must not query")
        ),
        list(...),
        keep.null = TRUE
      )
    )
  }
  for (station in list(NA, TRUE, 0, 1.5, "1 OR 1=1", "1.0", c(1, 2))) {
    testthat::expect_error(run(station = station), "Ungültige Stations-ID")
  }
  for (variable in list(NA, "TMK", c("Lufttemperatur", "Schneehoehe"))) {
    testthat::expect_error(run(variable = variable), "Ungültige Klimavariable")
  }
  for (threshold in list(NA, Inf, "10", TRUE, c(1, 2), -31, 41)) {
    testthat::expect_error(
      run(threshold = threshold),
      "Ungültiger Schwellenwert"
    )
  }
  testthat::expect_error(run(direction = "bad"), "Ungültige Schwellenrichtung")
  testthat::expect_error(run(include_current = "TRUE"), "Ungültige Auswahl")
  testthat::expect_error(run(today = "2026-01-01"), "Ungültiges Bezugsdatum")
  testthat::expect_identical(
    run(db_pool = NULL),
    app_functions$thresholds_empty_annual()
  )
  testthat::expect_error(
    run(query = function(...) stop("secret password")),
    "Die Klimadaten konnten nicht geladen werden"
  )
})

testthat::test_that("threshold module forwards filters, describes and plots counts", {
  shiny::testServer(
    app_functions$mod_thresholds_server,
    args = list(
      stations = function(...) c("Testort" = "42"),
      annual = function(
        pool,
        station,
        variable,
        threshold,
        direction,
        include_current
      ) {
        testthat::expect_identical(station, "42")
        testthat::expect_identical(variable, "Schneehoehe")
        testthat::expect_equal(threshold, 0)
        testthat::expect_identical(direction, "under")
        testthat::expect_true(include_current)
        data.frame(year = 2020L, n_threshold = 0L, n_days = 300L)
      }
    ),
    {
      session$setInputs(
        station = "42",
        variable = "Schneehoehe",
        threshold = 0,
        direction = "under",
        include_current = TRUE
      )
      testthat::expect_equal(data()$n_threshold, 0L)
      testthat::expect_match(output$description$html, "kleiner oder gleich")
      testthat::expect_match(output$description$html, "Testort")
      testthat::expect_match(output$threshold_input$html, "data-max=\"100\"")
      testthat::expect_true(nzchar(output$plot))
      session$setInputs(variable = "Sonnenscheindauer")
      testthat::expect_match(output$threshold_input$html, "data-max=\"24\"")
    }
  )
})

testthat::test_that("threshold bars use variable-specific gradients from the first tab", {
  shiny::testServer(
    app_functions$mod_thresholds_server,
    args = list(
      stations = function(...) c("Test" = "1"),
      annual = function(...) {
        data.frame(
          year = 2020:2021,
          n_threshold = c(10L, 100L),
          n_days = c(366L, 365L)
        )
      }
    ),
    {
      session$setInputs(
        station = "1",
        threshold = 10,
        direction = "over",
        include_current = FALSE
      )
      for (variable in app_functions$trends_variables()$name) {
        session$setInputs(variable = variable)
        plot <- jsonlite::fromJSON(output$plot, simplifyVector = FALSE)
        colors <- unlist(lapply(plot$x$data, function(trace) {
          trace$marker$color
        }))
        expected <- grDevices::col2rgb(app_functions$trends_fill_colors(
          variable
        ))
        testthat::expect_setequal(
          unique(colors),
          apply(expected, 2, function(rgb) {
            paste0("rgba(", paste(rgb, collapse = ","), ",1)")
          })
        )
      }
    }
  )
})

testthat::test_that("threshold module reports empty data and hides provider errors", {
  for (provider in list(
    function(...) app_functions$thresholds_empty_annual(),
    function(...) stop("secret password")
  )) {
    shiny::testServer(
      app_functions$mod_thresholds_server,
      args = list(stations = function(...) c("Test" = "1"), annual = provider),
      {
        session$setInputs(
          station = "1",
          variable = "Lufttemperatur",
          threshold = 10,
          direction = "over",
          include_current = FALSE
        )
        error <- tryCatch(output$plot, error = identity)
        testthat::expect_s3_class(error, "shiny.silent.error")
        testthat::expect_false(grepl("secret", conditionMessage(error)))
      }
    )
  }
})
