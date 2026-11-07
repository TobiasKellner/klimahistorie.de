testthat::test_that("the trends chart includes a filling loading spinner", {
  html <- htmltools::renderTags(app_functions$mod_trends_ui("trends"))$html
  testthat::expect_match(html, 'id="trends-plot"', fixed = TRUE)
  testthat::expect_match(html, "shiny-spinner-output-container", fixed = TRUE)
  testthat::expect_match(
    html,
    'shiny-spinner-output-container[^"]*html-fill-item[^"]*html-fill-container'
  )
  testthat::expect_match(html, 'height:100%;', fixed = TRUE)
  testthat::expect_false(grepl("height:450px", html, fixed = TRUE))
  testthat::expect_match(html, 'id="trends-show_map"', fixed = TRUE)
  testthat::expect_match(html, 'fa-map', fixed = TRUE)
})

testthat::test_that("the map modal displays the selected station and handles failures", {
  modal <- NULL
  calls <- character()
  shiny::testServer(
    app_functions$mod_trends_server,
    args = list(
      stations = function(pool) c("Station A" = "11", "Station B" = "22"),
      location = function(pool, station) {
        calls <<- c(calls, station)
        if (station == "22") {
          stop("password=secret")
        }
        data.frame(
          STATIONS_ID = 11L,
          Stationsname = "Station A",
          Bundesland = "Land",
          Stationshoehe = 100,
          geoBreite = 50,
          geoLaenge = 8
        )
      },
      show = function(ui) modal <<- htmltools::renderTags(ui)$html
    ),
    {
      session$setInputs(station = "11", show_map = 1)
      testthat::expect_identical(calls, "11")
      testthat::expect_match(modal, "Wetterstation: Station A", fixed = TRUE)
      testthat::expect_match(
        modal,
        paste0('id="', session$ns("station_map"), '"'),
        fixed = TRUE
      )
      testthat::expect_true(nzchar(output$station_map))
      session$setInputs(station = "22", show_map = 2)
      testthat::expect_identical(calls, c("11", "22"))
      testthat::expect_match(modal, "nicht verfügbar", fixed = TRUE)
      testthat::expect_false(grepl("password|secret", modal))
    }
  )
})

testthat::test_that("bar color gradients match each climate variable", {
  expected <- list(
    Lufttemperatur = c(low = "blue", high = "red"),
    Schneehoehe = c(low = "green", high = "blue"),
    Sonnenscheindauer = c(low = "black", high = "yellow"),
    Niederschlagshoehe = c(low = "brown", high = "blue")
  )
  for (variable in names(expected)) {
    testthat::expect_identical(
      app_functions$trends_fill_colors(variable),
      expected[[variable]]
    )
  }
  testthat::expect_error(
    app_functions$trends_fill_colors("unknown"),
    "Ungültige Klimavariable"
  )
})

testthat::test_that("trends queries selected filters and renders data", {
  calls <- list()
  provider <- function(pool, station, variable, month, include_current) {
    calls[[length(calls) + 1L]] <<- list(
      station,
      variable,
      month,
      include_current
    )
    data.frame(
      year = 2023:2025,
      value = c(8, 9, 10),
      n_days = c(365L, 366L, 365L)
    )
  }
  shiny::testServer(
    app_functions$mod_trends_server,
    args = list(
      db_pool = "fake",
      stations = function(pool) c("Teststation (11)" = "11"),
      annual = provider
    ),
    {
      session$setInputs(
        station = "11",
        variable = "Lufttemperatur",
        month = "0",
        include_current = FALSE,
        regline = FALSE
      )
      testthat::expect_equal(data()$value, c(8, 9, 10))
      testthat::expect_identical(
        tail(calls, 1)[[1]],
        list("11", "Lufttemperatur", "0", FALSE)
      )
      testthat::expect_match(
        output$description$html,
        "Teststation",
        fixed = TRUE
      )
      testthat::expect_true(nzchar(output$plot))
      session$setInputs(month = "2", include_current = TRUE, regline = TRUE)
      testthat::expect_true(nzchar(output$plot))
      testthat::expect_identical(
        tail(calls, 1)[[1]],
        list("11", "Lufttemperatur", "2", TRUE)
      )
      for (variable in app_functions$trends_variables()$name) {
        session$setInputs(variable = variable)
        testthat::expect_true(nzchar(output$plot))
      }
    }
  )
})

testthat::test_that("trends handles no data and redacts provider errors", {
  shiny::testServer(app_functions$mod_trends_server, {
    session$setInputs(station = "11", variable = "Lufttemperatur", month = "0")
    testthat::expect_error(data(), "Keine Stationen mit aktuellem DWD")
  })
  shiny::testServer(
    app_functions$mod_trends_server,
    args = list(
      db_pool = "fake",
      stations = function(pool) c("Station" = "11"),
      annual = function(...) stop("password=secret")
    ),
    {
      session$setInputs(
        station = "11",
        variable = "Lufttemperatur",
        month = "0"
      )
      testthat::expect_error(
        data(),
        "Die Klimadaten konnten nicht geladen werden"
      )
    }
  )
})
