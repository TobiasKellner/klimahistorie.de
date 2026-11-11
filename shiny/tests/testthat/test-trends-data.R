testthat::test_that("trends variables and German month choices are fixed", {
  variables <- app_functions$trends_variables()
  testthat::expect_identical(names(variables), c("name", "column", "unit"))
  testthat::expect_identical(
    variables$name,
    c(
      "Lufttemperatur",
      "Schneehoehe",
      "Sonnenscheindauer",
      "Niederschlagshoehe"
    )
  )
  testthat::expect_identical(
    variables$column,
    c("TMK", "SHK_TAG", "SDK", "RSK")
  )
  testthat::expect_identical(
    variables$unit,
    c("°C", "cm", "Stunden/Tag", "mm/Tag")
  )
  months <- app_functions$trends_month_choices()
  testthat::expect_identical(unname(months), as.character(0:12))
  testthat::expect_identical(
    names(months)[c(1, 4, 13)],
    c("Gesamtes Jahr", "März", "Dezember")
  )
})

testthat::test_that("station choices read the materialized view without reapplying metadata filters", {
  choices <- app_functions$trends_station_choices(
    "mock",
    query = function(pool, sql, params) {
      testthat::expect_identical(pool, "mock")
      testthat::expect_null(params)
      testthat::expect_match(
        sql,
        'FROM public."AktuelleTemperaturstationen"',
        fixed = TRUE
      )
      testthat::expect_match(
        sql,
        'ORDER BY "Stationsname", "STATIONS_ID"',
        fixed = TRUE
      )
      testthat::expect_false(grepl('WHERE|Stationstabelle', sql))
      testthat::expect_false(grepl('Tagesdaten', sql, fixed = TRUE))
      data.frame(
        id = c(9L, 2L, 9L, 3L),
        name = c("Zugspitze", "Aachen", "Alter Name", NA)
      )
    }
  )
  testthat::expect_identical(
    choices,
    c("Aachen" = "2", "Station" = "3", "Zugspitze" = "9")
  )
  testthat::expect_length(
    app_functions$trends_station_choices("mock", query = function(...) {
      data.frame()
    }),
    0L
  )
})

testthat::test_that("annual queries bind station, month and date and whitelist columns", {
  variables <- app_functions$trends_variables()
  for (i in seq_len(nrow(variables))) {
    result <- app_functions$trends_annual_data(
      "mock",
      "42",
      variables$name[i],
      "3",
      today = as.Date("2026-11-06"),
      query = function(pool, sql, params) {
        testthat::expect_identical(pool, "mock")
        testthat::expect_identical(params, list(42L, 3L, "20251231"))
        testthat::expect_match(
          sql,
          sprintf('avg(NULLIF("%s", -999)) AS value', variables$column[i]),
          fixed = TRUE
        )
        testthat::expect_match(
          sql,
          sprintf('count(NULLIF("%s", -999)) AS n_days', variables$column[i]),
          fixed = TRUE
        )
        testthat::expect_match(sql, '"STATIONS_ID" = $1', fixed = TRUE)
        testthat::expect_match(
          sql,
          'substr("MESS_DATUM", 5, 2)::integer = $2::integer',
          fixed = TRUE
        )
        testthat::expect_match(sql, '"MESS_DATUM" <= $3::text', fixed = TRUE)
        testthat::expect_match(
          sql,
          'substr("MESS_DATUM", 1, 4)::integer AS year',
          fixed = TRUE
        )
        testthat::expect_false(grepl("round\\(|20251231|= 42", sql))
        data.frame(
          year = c(2020, 2019, 2021, 2022),
          value = c(2.26, 1.24, NA, Inf),
          n_days = c(31, 31, 0, 1)
        )
      }
    )
    testthat::expect_identical(
      result,
      data.frame(
        year = c(2019L, 2020L),
        value = c(1.2, 2.3),
        n_days = c(31L, 31L)
      )
    )
  }
  for (date in c("2026-01-01", "2026-11-06")) {
    app_functions$trends_annual_data(
      "mock",
      42,
      "Lufttemperatur",
      include_current = TRUE,
      today = as.Date(date),
      query = function(pool, sql, params) {
        testthat::expect_identical(params, list(42L, 0L, gsub("-", "", date)))
        data.frame()
      }
    )
  }
})

testthat::test_that("only complete calendar years and months are returned", {
  run <- function(
    month,
    years,
    days,
    today = "2026-11-06",
    include_current = FALSE
  ) {
    app_functions$trends_annual_data(
      "mock",
      1,
      "Lufttemperatur",
      month,
      today = as.Date(today),
      include_current = include_current,
      query = function(...) data.frame(year = years, value = 10, n_days = days)
    )
  }
  testthat::expect_identical(
    run(0, 2019:2022, c(365, 365, 364, 365))$year,
    c(2019L, 2022L)
  )
  testthat::expect_identical(run(0, 2020, 366)$year, 2020L)
  testthat::expect_identical(
    run(2, 2019:2022, c(28, 28, 27, 28))$year,
    c(2019L, 2022L)
  )
  testthat::expect_identical(run(2, 2020, 29)$year, 2020L)
  testthat::expect_length(run(4, 2020, 29)$year, 0L)
  testthat::expect_identical(run(4, 2020, 30)$year, 2020L)
  testthat::expect_identical(run(12, 2020, 31)$year, 2020L)
  testthat::expect_length(run(0, 2026, 365, include_current = TRUE)$year, 0L)
  testthat::expect_identical(
    run(2, 2026, 28, include_current = TRUE)$year,
    2026L
  )
  testthat::expect_length(run(11, 2026, 30, include_current = TRUE)$year, 0L)
  testthat::expect_length(run(12, 2026, 31, include_current = TRUE)$year, 0L)
})

testthat::test_that("invalid trend inputs never reach a provider", {
  run <- function(...) {
    app_functions$trends_annual_data("mock", ..., query = function(...) {
      stop("provider must not run")
    })
  }
  for (station in list(
    NULL,
    NA,
    TRUE,
    c(1, 2),
    1.5,
    0,
    -1,
    Inf,
    2147483648,
    "1 OR 1=1",
    " 1",
    "1.0"
  )) {
    testthat::expect_error(
      run(station, "Lufttemperatur"),
      "Ungültige Stations-ID",
      fixed = TRUE
    )
  }
  for (variable in list(
    NULL,
    NA,
    c("Lufttemperatur", "Schneehoehe"),
    "TMK",
    'TMK"; DROP TABLE x; --'
  )) {
    testthat::expect_error(
      run(1, variable),
      "Ungültige Klimavariable",
      fixed = TRUE
    )
  }
  for (month in list(NULL, NA, TRUE, c(1, 2), -1, 13, 2.5, "3;SELECT", "03")) {
    testthat::expect_error(
      run(1, "Lufttemperatur", month),
      "Ungültiger Monat",
      fixed = TRUE
    )
  }
  for (flag in list(NULL, NA, 0, "TRUE", c(TRUE, FALSE))) {
    testthat::expect_error(
      run(1, "Lufttemperatur", include_current = flag),
      "Ungültige Auswahl",
      fixed = TRUE
    )
  }
  for (date in list(
    NULL,
    as.Date(NA),
    "2026-01-01",
    as.Date(c("2025-01-01", "2026-01-01"))
  )) {
    testthat::expect_error(
      run(1, "Lufttemperatur", today = date),
      "Ungültiges Bezugsdatum",
      fixed = TRUE
    )
  }
})

testthat::test_that("null pools and all missing data yield empty results", {
  never <- function(...) stop("provider must not run")
  testthat::expect_length(
    app_functions$trends_station_choices(NULL, query = never),
    0L
  )
  expected <- data.frame(year = integer(), value = double(), n_days = integer())
  testthat::expect_identical(
    app_functions$trends_annual_data(NULL, 1, "Lufttemperatur", query = never),
    expected
  )
  for (data in list(
    data.frame(),
    data.frame(year = 2020L, value = NA_real_, n_days = 0L)
  )) {
    testthat::expect_identical(
      app_functions$trends_annual_data(
        "mock",
        1,
        "Lufttemperatur",
        query = function(...) data
      ),
      expected
    )
  }
})

testthat::test_that("provider errors are redacted in German", {
  failing <- function(...) {
    stop("postgres://user:secret@internal-host SELECT password")
  }
  for (call in list(
    function() app_functions$trends_station_choices("mock", query = failing),
    function() {
      app_functions$trends_annual_data(
        "mock",
        1,
        "Lufttemperatur",
        query = failing
      )
    }
  )) {
    error <- tryCatch(call(), error = identity)
    testthat::expect_s3_class(error, "error")
    testthat::expect_identical(
      conditionMessage(error),
      "Die Klimadaten konnten nicht geladen werden. Bitte versuchen Sie es später erneut."
    )
    testthat::expect_null(conditionCall(error))
  }
})

testthat::test_that("regression is unweighted and requires distinct valid years", {
  empty <- data.frame(year = integer(), value = double())
  for (data in list(
    data.frame(),
    data.frame(year = 2020L, value = 1),
    data.frame(year = c(2020, 2020, NA, Inf), value = c(1, 2, 3, 4)),
    data.frame(year = c(2020, 2021), value = c(NA, Inf))
  )) {
    testthat::expect_identical(app_functions$trends_regression(data), empty)
  }
  data <- data.frame(
    year = c(2022L, 2020L, 2021L, 2023L),
    value = c(9, 1, 2, NA),
    n_days = c(1, 365, 5, 0)
  )
  result <- app_functions$trends_regression(data)
  testthat::expect_identical(result$year, 2020:2022)
  testthat::expect_equal(result$value, c(0, 4, 8), tolerance = 1e-8)
  testthat::expect_identical(names(result), c("year", "value"))
})
