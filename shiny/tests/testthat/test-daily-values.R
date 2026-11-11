testthat::test_that("daily values query raw columns with bound station and date", {
  result <- app_functions$daily_values_data(
    "fake",
    "11",
    as.Date("2026-10-07"),
    query = function(pool, sql, params) {
      testthat::expect_identical(pool, "fake")
      testthat::expect_identical(params, list(11L, "20261007"))
      testthat::expect_match(sql, '"MESS_DATUM" = $2::text', fixed = TRUE)
      testthat::expect_match(sql, 'FROM public."Tagesdaten"', fixed = TRUE)
      data.frame(
        TMK = -2.34,
        TNK = -999,
        TXK = NA_real_,
        SDK = 0,
        RSK = 1,
        SHK_TAG = 0,
        FM = 2,
        FX = 3,
        PM = 1000
      )
    }
  )
  testthat::expect_equal(result$TMK, -2.34)
  testthat::expect_true(is.na(result$TNK))
  testthat::expect_true(is.na(result$TXK))
  testthat::expect_equal(result$SDK, 0)
  testthat::expect_identical(
    app_functions$daily_values_format(result$TMK, "°C"),
    "-2,3 °C"
  )
  testthat::expect_identical(
    app_functions$daily_values_format(0, "mm"),
    "0,0 mm"
  )
  testthat::expect_identical(
    app_functions$daily_values_format(-999, "cm"),
    "Nicht verfügbar"
  )
  testthat::expect_equal(
    nrow(app_functions$daily_values_data(NULL, "11", Sys.Date())),
    0L
  )
  testthat::expect_equal(
    nrow(app_functions$daily_values_data(
      "fake",
      "11",
      Sys.Date(),
      query = function(...) data.frame()
    )),
    0L
  )
  testthat::expect_error(
    app_functions$daily_values_data(NULL, "11 OR 1=1", Sys.Date()),
    "Stations-ID"
  )
  testthat::expect_error(
    app_functions$daily_values_data(NULL, "11", "20261007"),
    "Datum"
  )
  testthat::expect_error(
    app_functions$daily_values_data(
      "fake",
      "11",
      Sys.Date(),
      query = function(...) stop("password=secret")
    ),
    "Die Klimadaten konnten nicht geladen werden"
  )
  testthat::expect_equal(
    app_functions$daily_values_default_date(as.Date("2024-03-31")),
    as.Date("2024-02-29")
  )
})

testthat::test_that("daily values render nine boxes and follow selected filters", {
  calls <- list()
  shiny::testServer(
    app_functions$mod_daily_values_server,
    args = list(
      stations = function(pool) c("<Teststation>" = "11"),
      daily = function(pool, station, date) {
        calls[[length(calls) + 1L]] <<- list(station, date)
        if (date == as.Date("2026-10-08")) {
          return(app_functions$daily_values_data(NULL, station, date))
        }
        data.frame(
          TMK = 8,
          TNK = -999,
          TXK = 10,
          SDK = 0,
          RSK = 1,
          SHK_TAG = 0,
          FM = 2,
          FX = 3,
          PM = 1000
        )
      }
    ),
    {
      session$setInputs(station = "11", date = as.Date("2026-10-07"))
      html <- output$values$html
      testthat::expect_equal(
        lengths(regmatches(
          html,
          gregexpr('class="[^\"]*bslib-value-box ', html)
        )),
        9L
      )
      testthat::expect_match(html, "8,0 °C", fixed = TRUE)
      testthat::expect_match(html, "Nicht verfügbar", fixed = TRUE)
      testthat::expect_match(
        output$description$html,
        "&lt;Teststation&gt;",
        fixed = TRUE
      )
      testthat::expect_identical(
        tail(calls, 1)[[1]],
        list("11", as.Date("2026-10-07"))
      )
      session$setInputs(date = as.Date("2026-10-08"))
      testthat::expect_true(nzchar(output$values$html))
      testthat::expect_equal(
        lengths(regmatches(
          output$values$html,
          gregexpr("Nicht verfügbar", output$values$html)
        )),
        9L
      )
    }
  )
})

testthat::test_that("daily value provider errors are neutral", {
  shiny::testServer(
    app_functions$mod_daily_values_server,
    args = list(
      stations = function(pool) c("Station" = "11"),
      daily = function(...) stop("password=secret")
    ),
    {
      session$setInputs(station = "11", date = Sys.Date())
      testthat::expect_error(
        output$values,
        "Die Tagesdaten konnten nicht geladen werden",
        fixed = TRUE
      )
    }
  )
})
