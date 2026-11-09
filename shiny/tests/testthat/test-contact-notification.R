testthat::test_that("successful sending closes the modal and shows an icon notification", {
  notices <- list()
  closed <- 0L
  server <- function(input, output, session) {
    app_functions$contact_server(
      input,
      session,
      output = output,
      config = function() list(),
      send = function(...) invisible(NULL),
      close = function(session) {
        closed <<- closed + 1L
      },
      notify = function(ui, type, ...) {
        notices[[length(notices) + 1L]] <<- list(ui = ui, type = type)
      }
    )
  }
  shiny::testServer(server, {
    session$flushReact()
    session$setInputs(send_message = 1)
    testthat::expect_equal(closed, 0L)
    notices <<- list()
    session$setInputs(
      message_subject = "Test",
      message_email = "test@example.org",
      message_text = "Test",
      send_message = 2
    )
    testthat::expect_equal(closed, 1L)
    testthat::expect_length(notices, 1L)
    testthat::expect_identical(notices[[1]]$type, "message")
    html <- htmltools::renderTags(notices[[1]]$ui)$html
    testthat::expect_match(html, "erfolgreich versendet", fixed = TRUE)
    testthat::expect_match(html, "fa-circle-check", fixed = TRUE)
    testthat::expect_null(output$message_status)
  })
})

testthat::test_that("disabled SMTP gives a visible notification without sending", {
  notices <- list()
  closed <- 0L
  server <- function(input, output, session) {
    app_functions$contact_server(
      input,
      session,
      output = output,
      config = function() NULL,
      send = function(...) stop("must not send"),
      close = function(session) {
        closed <<- closed + 1L
      },
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
    testthat::expect_equal(closed, 0L)
    testthat::expect_match(notices[[1]], "deaktiviert", fixed = TRUE)
    testthat::expect_match(
      output$message_status$html,
      "deaktiviert",
      fixed = TRUE
    )
  })
})
