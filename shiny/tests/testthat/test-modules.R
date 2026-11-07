testthat::test_that("each module returns its reactive filter state", {
  cases <- list(
    trends = list(
      station = "Berlin",
      variable = "Lufttemperatur",
      month = "Gesamtes Jahr"
    ),
    daily_values = list(station = "Berlin", date = as.Date("2026-11-06")),
    year_comparison = list(station = "Berlin", years = "2024,2023"),
    daily_history = list(station = "Berlin", date = as.Date("2026-11-06")),
    records = list(station = "Berlin", record_type = "Minimum"),
    thresholds = list(
      station = "Berlin",
      variable = "Schneehoehe",
      threshold = 10,
      direction = "over",
      include_current = FALSE
    )
  )
  for (id in names(cases)) {
    expected <- cases[[id]]
    shiny::testServer(app_functions[[paste0("mod_", id, "_server")]], {
      do.call(session$setInputs, expected)
      testthat::expect_identical(session$returned(), expected)
      session$setInputs(station = "Hamburg")
      expected$station <- "Hamburg"
      testthat::expect_identical(session$returned(), expected)
    })
  }
})

testthat::test_that("two module instances do not share inputs", {
  server <- function(input, output, session) {
    first <- app_functions$mod_trends_server("first")
    second <- app_functions$mod_trends_server("second")
  }
  shiny::testServer(server, {
    session$setInputs(`first-station` = "Berlin", `second-station` = "Hamburg")
    testthat::expect_identical(first()$station, "Berlin")
    testthat::expect_identical(second()$station, "Hamburg")
  })
})
