testthat::test_that("disabled SMTP gives a visible notification without sending", {
  notices <- list()
  server <- function(input, output, session) {
    app_functions$contact_server(
      input,
      session,
      output = output,
      config = function() NULL,
      send = function(...) stop("must not send"),
      notify = function(ui, ...) {
        notices[[length(notices) + 1L]] <<- ui
      }
    )
  }
  shiny::testServer(server, {
    session$flushReact()
    session$setInputs(
      message_subject = "Test",
      message_email = "test@example.org",
      message_text = "Test",
      send_message = 1
    )
    testthat::expect_length(notices, 1L)
    testthat::expect_match(notices[[1]], "deaktiviert", fixed = TRUE)
    testthat::expect_match(
      output$message_status$html,
      "deaktiviert",
      fixed = TRUE
    )
  })
})
