testthat::test_that("all station tabs have namespaced green map buttons", {
  for (id in head(app_functions$app_navigation()$id, 6)) {
    html <- htmltools::renderTags(app_functions[[paste0("mod_", id, "_ui")]](
      id
    ))$html
    testthat::expect_match(html, paste0('id="', id, '-show_map"'), fixed = TRUE)
    testthat::expect_match(html, "btn-success", fixed = TRUE)
    testthat::expect_match(html, "fa-map", fixed = TRUE)
  }
})

testthat::test_that("additional map dialogs follow the station selected in each tab", {
  for (id in c("year_comparison", "daily_history", "records", "thresholds")) {
    modal <- NULL
    requested <- NULL
    shiny::testServer(
      app_functions[[paste0("mod_", id, "_server")]],
      args = list(
        stations = function(pool) c("Station A" = "11", "Station B" = "22"),
        location = function(pool, station) {
          requested <<- station
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
        testthat::expect_identical(requested, "11")
        testthat::expect_match(modal, "Wetterstation: Station A", fixed = TRUE)
        testthat::expect_match(modal, session$ns("station_map"), fixed = TRUE)
        testthat::expect_match(modal, "fa-xmark", fixed = TRUE)
        testthat::expect_true(nzchar(output$station_map))
        session$setInputs(station = "22", show_map = 2)
        testthat::expect_identical(requested, "22")
        testthat::expect_match(modal, "nicht verfügbar", fixed = TRUE)
        testthat::expect_false(grepl("password|secret", modal))
      }
    )
  }
})
