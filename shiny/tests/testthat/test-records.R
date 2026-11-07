testthat::test_that("record queries rank each raw metric with earliest-date ties", {
  for (type in c("Maximum", "Minimum")) {
    result <- app_functions$records_data(
      "fake",
      "11",
      type,
      query = function(pool, sql, params) {
        testthat::expect_identical(params, list(11L))
        testthat::expect_match(
          sql,
          paste0(
            'ORDER BY "TMK" ',
            if (type == "Maximum") "DESC" else "ASC",
            ', "MESS_DATUM" ASC LIMIT 1'
          ),
          fixed = TRUE
        )
        testthat::expect_match(sql, '"TNK" != -999', fixed = TRUE)
        testthat::expect_match(sql, "Infinity", fixed = TRUE)
        testthat::expect_equal(
          lengths(regmatches(sql, gregexpr("LIMIT 1", sql))),
          9L
        )
        data.frame(
          column = c("TMK", "SDK"),
          date = c("20200101", "20210101"),
          value = c(-2.34, 0)
        )
      }
    )
    testthat::expect_equal(nrow(result), 9L)
    testthat::expect_equal(result$value[1], -2.34)
    testthat::expect_equal(result$date[1], as.Date("2020-01-01"))
    testthat::expect_equal(result$value[4], 0)
    testthat::expect_true(is.na(result$value[2]))
    testthat::expect_true(is.na(result$date[2]))
  }
  testthat::expect_true(all(is.na(
    app_functions$records_data(NULL, "11", "Maximum")$value
  )))
  testthat::expect_error(
    app_functions$records_data(NULL, "11 OR 1=1", "Maximum"),
    "Stations-ID"
  )
  testthat::expect_error(
    app_functions$records_data(NULL, "11", "unknown"),
    "Rekordtyp"
  )
  testthat::expect_error(
    app_functions$records_data("fake", "11", "Maximum", query = function(...) {
      data.frame(column = "TMK", date = "20230229", value = 1)
    }),
    "Rekorddatenstruktur"
  )
})

testthat::test_that("records module renders nine tiles and responds to station and mode", {
  requested <- NULL
  shiny::testServer(
    app_functions$mod_records_server,
    args = list(
      stations = function(pool) c("<Station>" = "11", "Other" = "22"),
      records = function(pool, station, record_type) {
        requested <<- list(station, record_type)
        result <- app_functions$records_data(NULL, station, record_type)
        result$value[1] <- if (record_type == "Maximum") 30 else -10
        result$date[1] <- as.Date("2020-01-01")
        result
      }
    ),
    {
      session$setInputs(station = "11", record_type = "Maximum")
      html <- output$values$html
      testthat::expect_equal(
        lengths(regmatches(
          html,
          gregexpr('class="[^\"]*bslib-value-box ', html)
        )),
        9L
      )
      testthat::expect_match(html, "30,0 °C", fixed = TRUE)
      testthat::expect_match(html, "01.01.2020", fixed = TRUE)
      testthat::expect_match(html, "Nicht verfügbar", fixed = TRUE)
      testthat::expect_match(
        output$description$html,
        "&lt;Station&gt;",
        fixed = TRUE
      )
      session$setInputs(record_type = "Minimum")
      testthat::expect_match(output$values$html, "-10,0 °C", fixed = TRUE)
      testthat::expect_identical(requested, list("11", "Minimum"))
      session$setInputs(station = "22")
      testthat::expect_true(nzchar(output$values$html))
      testthat::expect_identical(requested, list("22", "Minimum"))
    }
  )
})

testthat::test_that("record provider errors are neutral", {
  shiny::testServer(
    app_functions$mod_records_server,
    args = list(
      stations = function(pool) c("Station" = "11"),
      records = function(...) stop("password=secret")
    ),
    {
      session$setInputs(station = "11", record_type = "Maximum")
      testthat::expect_error(
        output$values,
        "Die Klimarekorde konnten nicht geladen werden",
        fixed = TRUE
      )
    }
  )
})
