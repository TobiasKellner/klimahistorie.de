testthat::test_that("a selected station map uses a bound station ID", {
  result <- app_functions$stations_map_data(
    "fake",
    station = "11",
    query = function(pool, sql, params) {
      testthat::expect_match(sql, 'AND "STATIONS_ID" = $1', fixed = TRUE)
      testthat::expect_identical(params, list(11L))
      data.frame()
    }
  )
  testthat::expect_equal(nrow(result), 0L)
  testthat::expect_error(
    app_functions$stations_map_data("fake", station = "11 OR 1=1"),
    "Ungültige Stations-ID"
  )
})

testthat::test_that("station map uses active metadata and valid coordinates", {
  locations <- app_functions$stations_map_data(
    "fake",
    query = function(pool, sql, params) {
      testthat::expect_identical(pool, "fake")
      testthat::expect_null(params)
      testthat::expect_match(
        sql,
        'FROM public."AktuelleTemperaturstationen"',
        fixed = TRUE
      )
      data.frame(
        STATIONS_ID = c(1L, 1L, 2L, 3L, 4L, 5L),
        Stationsname = c("A", "Duplicate", "B", "C", "D", "E"),
        Bundesland = "Land",
        Stationshoehe = 100,
        geoBreite = c(50, 50, NA, 91, 51, 52),
        geoLaenge = c(8, 8, 9, 9, Inf, 181)
      )
    }
  )
  testthat::expect_identical(locations$STATIONS_ID, 1L)
  testthat::expect_equal(nrow(app_functions$stations_map_data(NULL)), 0L)
  testthat::expect_equal(
    nrow(app_functions$stations_map_data("fake", query = function(...) {
      data.frame()
    })),
    0L
  )
})

testthat::test_that("map labels escape HTML and include station metadata", {
  locations <- data.frame(
    STATIONS_ID = 11L,
    Stationsname = "<script>Test</script>",
    Bundesland = NA_character_,
    Stationshoehe = 120,
    geoBreite = 50,
    geoLaenge = 8
  )
  label <- as.character(app_functions$stations_map_labels(locations)[[1]])
  testthat::expect_match(
    label,
    "&lt;script&gt;Test&lt;/script&gt;",
    fixed = TRUE
  )
  testthat::expect_match(label, "Keine Angabe", fixed = TRUE)
  testthat::expect_match(label, "120 m", fixed = TRUE)
  testthat::expect_match(label, "Stations-ID: 11", fixed = TRUE)
  shiny::testServer(
    app_functions$view_stations_server,
    args = list(
      db_pool = "fake",
      stations = function(pool) locations
    ),
    {
      session$flushReact()
      testthat::expect_true(nzchar(output$map))
      testthat::expect_identical(data()$STATIONS_ID, 11L)
    }
  )
})

testthat::test_that("map UI is namespaced and errors are neutral", {
  html <- htmltools::renderTags(app_functions$view_stations_ui())$html
  testthat::expect_match(html, 'id="stations-map"', fixed = TRUE)
  testthat::expect_false(grepl("Platzhalter", html))
  shiny::testServer(app_functions$view_stations_server, {
    testthat::expect_error(output$map, "Keine aktiven Stationen")
  })
  shiny::testServer(
    app_functions$view_stations_server,
    args = list(
      db_pool = "fake",
      stations = function(...) stop("password=secret")
    ),
    {
      testthat::expect_error(
        output$map,
        "Die Stationskarte konnte nicht geladen werden",
        fixed = TRUE
      )
    }
  )
})
