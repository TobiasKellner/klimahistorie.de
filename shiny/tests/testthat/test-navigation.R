testthat::test_that("navigation forwards valid values and ignores unknown ones", {
  calls <- list()
  server <- function(input, output, session) {
    app_functions$navigation_server(
      input,
      session,
      select = function(id, selected, session) {
        calls[[length(calls) + 1L]] <<- list(id = id, selected = selected)
      }
    )
  }
  shiny::testServer(server, {
    for (id in app_functions$app_navigation()$id) {
      session$setInputs(sidebar_tabs = id)
    }
    testthat::expect_length(calls, 9L)
    testthat::expect_identical(
      vapply(calls, `[[`, "", "selected"),
      app_functions$app_navigation()$id
    )
    session$setInputs(sidebar_tabs = "unknown")
    testthat::expect_length(calls, 9L)
  })
})
