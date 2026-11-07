testthat::test_that("overview metrics and annual query have the required interface", {
  metrics <- app_functions$overview_metrics()
  testthat::expect_identical(
    metrics$key,
    c("temperature", "frost", "heat", "rain")
  )
  testthat::expect_identical(
    metrics$label,
    c("Jahresmitteltemperatur", "Frosttage", "Heiße Tage", "Niederschlagssumme")
  )
  testthat::expect_identical(metrics$unit, c("°C", "Tage", "Tage", "mm"))
  testthat::expect_identical(
    metrics$icon,
    c("temperature-half", "snowflake", "sun", "umbrella")
  )
  testthat::expect_identical(
    metrics$theme,
    c(
      "bg-gradient-orange-red",
      "bg-gradient-blue-indigo",
      "bg-gradient-yellow-orange",
      "bg-gradient-teal-cyan"
    )
  )

  current_year <- as.integer(format(Sys.Date(), "%Y"))
  result <- app_functions$overview_annual_data(
    "mock",
    "42",
    query = function(pool, sql, params) {
      testthat::expect_identical(pool, "mock")
      testthat::expect_identical(params, list(42L, current_year))
      testthat::expect_match(sql, '"STATIONS_ID" = $1', fixed = TRUE)
      testthat::expect_match(sql, '$2::integer', fixed = TRUE)
      for (column in c("TMK", "TNK", "TXK", "RSK")) {
        testthat::expect_match(
          sql,
          sprintf('NULLIF("%s", -999)', column),
          fixed = TRUE
        )
      }
      data.frame(
        year = c(2020L, 2021L, current_year),
        temperature = c(10, 11, 12),
        frost = c(20, 21, 22),
        heat = c(3, 4, 5),
        rain = c(700, 800, 900),
        n_temperature = c(366L, 365L, 365L),
        n_frost = c(366L, 364L, 365L),
        n_heat = c(366L, 365L, 365L),
        n_rain = c(366L, 365L, 365L),
        last_date = c("20201231", "20211231", paste0(current_year, "1231"))
      )
    }
  )
  testthat::expect_identical(
    result$expected,
    c(
      366L,
      365L,
      if (
        current_year %% 4L == 0L &&
          (current_year %% 100L != 0L || current_year %% 400L == 0L)
      ) {
        366L
      } else {
        365L
      }
    )
  )
  testthat::expect_equal(result$temperature[1:2], c(10, 11))
  testthat::expect_true(is.na(result$frost[2]))
  testthat::expect_true(all(is.na(result[
    3,
    c("temperature", "frost", "heat", "rain")
  ])))
  testthat::expect_s3_class(result$last_date, "Date")
})

testthat::test_that("overview helpers require complete strict reference data", {
  years <- 1991:2020
  data <- data.frame(
    year = years,
    temperature = as.numeric(years - 1990),
    frost = 1,
    heat = 2,
    rain = 3
  )
  testthat::expect_equal(
    app_functions$overview_reference(data, "temperature"),
    mean(1:30)
  )
  data$temperature[1] <- NA_real_
  testthat::expect_identical(
    app_functions$overview_reference(data, "temperature"),
    NA_real_
  )
  testthat::expect_identical(
    app_functions$overview_reference(data, "unknown"),
    NA_real_
  )
  testthat::expect_identical(
    app_functions$overview_default_year(
      data.frame(year = c(2024L, 2025L, 2026L), temperature = c(1, NA, 2)),
      as.Date("2026-07-01")
    ),
    "2024"
  )
  testthat::expect_identical(
    app_functions$overview_default_year(
      data.frame(year = 2026L, temperature = NA_real_),
      as.Date("2026-07-01")
    ),
    "2026"
  )
  testthat::expect_identical(
    app_functions$overview_default_year(data.frame()),
    character()
  )
})

testthat::test_that("overview validates station and returns a typed empty result", {
  expected <- app_functions$overview_empty_annual()
  testthat::expect_identical(
    app_functions$overview_annual_data(NULL, "1", query = function(...) {
      stop("must not run")
    }),
    expected
  )
  for (station in list(
    NULL,
    NA,
    TRUE,
    c(1, 2),
    0,
    -1,
    1.5,
    "1 OR 1=1",
    2147483648
  )) {
    testthat::expect_error(
      app_functions$overview_annual_data(NULL, station),
      "Stations-ID"
    )
  }
  testthat::expect_error(
    app_functions$overview_annual_data("mock", 1, query = function(...) {
      stop("password=secret")
    }),
    "Die Klimadaten konnten nicht geladen werden"
  )
})
