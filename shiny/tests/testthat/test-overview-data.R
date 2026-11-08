testthat::test_that("overview metrics and annual query have the required interface", {
  metrics <- app_functions$overview_metrics()
  testthat::expect_identical(
    metrics$key,
    c(
      "temperature",
      "frost",
      "heat",
      "rain",
      "max_temperature",
      "min_temperature",
      "sunshine",
      "snow"
    )
  )
  testthat::expect_identical(
    metrics$label,
    c(
      "Jahresmitteltemperatur",
      "Frosttage",
      "Heiße Tage",
      "Niederschlagssumme",
      "Maximaltemperatur",
      "Minimaltemperatur",
      "Sonnenscheindauer",
      "Tage mit Schneedecke"
    )
  )
  testthat::expect_identical(
    metrics$unit,
    c("°C", "Tage", "Tage", "mm", "°C", "°C", "Stunden", "Tage")
  )
  testthat::expect_identical(
    metrics$icon,
    c(
      "temperature-half",
      "icicles",
      "fire",
      "umbrella",
      "temperature-full",
      "temperature-empty",
      "sun",
      "snowflake"
    )
  )
  testthat::expect_identical(
    metrics$theme,
    c(
      "orange",
      "blue",
      "red",
      "green",
      "pink",
      "purple",
      "yellow",
      "teal"
    )
  )

  testthat::expect_identical(anyDuplicated(metrics$icon), 0L)
  testthat::expect_identical(anyDuplicated(metrics$theme), 0L)

  current_year <- as.integer(format(Sys.Date(), "%Y"))
  result <- app_functions$overview_annual_data(
    "mock",
    "42",
    query = function(pool, sql, params) {
      testthat::expect_identical(pool, "mock")
      testthat::expect_identical(params, list(42L, current_year))
      testthat::expect_match(sql, '"STATIONS_ID" = $1', fixed = TRUE)
      testthat::expect_match(sql, '$2::integer', fixed = TRUE)
      for (column in c("TMK", "TNK", "TXK", "RSK", "SDK", "SHK_TAG")) {
        testthat::expect_match(
          sql,
          sprintf('NULLIF("%s", -999)', column),
          fixed = TRUE
        )
      }
      testthat::expect_match(
        sql,
        'array_agg("MESS_DATUM" ORDER BY NULLIF("TXK", -999) DESC NULLS LAST, "MESS_DATUM")',
        fixed = TRUE
      )
      testthat::expect_match(
        sql,
        'array_agg("MESS_DATUM" ORDER BY NULLIF("TNK", -999) ASC NULLS LAST, "MESS_DATUM")',
        fixed = TRUE
      )
      testthat::expect_match(
        sql,
        'sum(NULLIF("SDK", -999)) AS sunshine',
        fixed = TRUE
      )
      testthat::expect_match(
        sql,
        'count(NULLIF("SHK_TAG", -999)) FILTER (WHERE NULLIF("SHK_TAG", -999) > 0) AS snow',
        fixed = TRUE
      )
      data.frame(
        year = c(2020L, 2021L, current_year),
        temperature = c(10, 11, 12),
        frost = c(20, 21, 22),
        heat = c(3, 4, 5),
        rain = c(700, 800, 900),
        max_temperature = c(30, 31, 32),
        min_temperature = c(-10, -11, -12),
        sunshine = c(1700, 1800, 1900),
        snow = c(10, 11, 12),
        n_temperature = c(366L, 364L, 365L),
        n_frost = c(366L, 364L, 365L),
        n_heat = c(366L, 364L, 365L),
        n_rain = c(366L, 364L, 365L),
        n_max_temperature = c(366L, 364L, 365L),
        n_min_temperature = c(366L, 364L, 365L),
        n_sunshine = c(366L, 364L, 365L),
        n_snow = c(366L, 364L, 365L),
        last_date = c("20201231", "20211231", paste0(current_year, "1231")),
        max_temperature_date = c(
          "20200801",
          "20210801",
          paste0(current_year, "0801")
        ),
        min_temperature_date = c(
          "20200201",
          "20210201",
          paste0(current_year, "0201")
        )
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
  testthat::expect_equal(result$temperature[1], 10)
  testthat::expect_true(all(is.na(result[2, metrics$key])))
  testthat::expect_identical(result$max_temperature_date[2], as.Date(NA))
  testthat::expect_identical(result$min_temperature_date[2], as.Date(NA))
  testthat::expect_true(all(is.na(result[
    3,
    metrics$key
  ])))
  testthat::expect_s3_class(result$last_date, "Date")
  testthat::expect_s3_class(result$max_temperature_date, "Date")
  testthat::expect_s3_class(result$min_temperature_date, "Date")
  testthat::expect_identical(result$max_temperature_date[3], as.Date(NA))
  testthat::expect_identical(result$min_temperature_date[3], as.Date(NA))
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
  data$max_temperature <- 20
  data$min_temperature <- -5
  data$sunshine <- 1500
  data$snow <- 10
  testthat::expect_identical(
    app_functions$overview_reference(data, "max_temperature"),
    NA_real_
  )
  testthat::expect_identical(
    app_functions$overview_reference(data, "min_temperature"),
    NA_real_
  )
  testthat::expect_equal(
    app_functions$overview_reference(data, "sunshine"),
    1500
  )
  testthat::expect_equal(app_functions$overview_reference(data, "snow"), 10)
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
