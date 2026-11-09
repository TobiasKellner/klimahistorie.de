smtp_fixture <- function() {
  list(
    username = "kontakt@example.org",
    recipient = "inbox@example.org",
    password = "test-only",
    server = "smtps://smtp.ionos.de:465"
  )
}

testthat::test_that("SMTP is opt-in and passwords are loaded from a file", {
  values <- c(
    CONTACT_SMTP_ENABLED = "true",
    CONTACT_SMTP_USERNAME = "kontakt@example.org",
    CONTACT_SMTP_PASSWORD_FILE = "/not-a-real-secret"
  )
  getenv <- function(name, unset = "") {
    if (name %in% names(values)) unname(values[[name]]) else unset
  }
  read_secret <- function(path, warn) {
    testthat::expect_identical(path, "/not-a-real-secret")
    "test-only"
  }
  config <- app_functions$contact_smtp_config(getenv, read_secret)
  testthat::expect_identical(config$recipient, config$username)
  testthat::expect_identical(config$server, "smtps://smtp.ionos.de:465")
  values[["CONTACT_SMTP_PORT"]] <- "587"
  testthat::expect_identical(
    app_functions$contact_smtp_config(getenv, read_secret)$server,
    "smtp://smtp.ionos.de:587"
  )
  values[["CONTACT_SMTP_PORT"]] <- "25"
  testthat::expect_error(app_functions$contact_smtp_config(getenv, read_secret))
  values[["CONTACT_SMTP_PORT"]] <- "465"
  testthat::expect_error(app_functions$contact_smtp_config(
    getenv,
    function(...) c("two", "lines")
  ))
  values[["CONTACT_SMTP_ENABLED"]] <- "false"
  testthat::expect_null(app_functions$contact_smtp_config(
    getenv,
    function(...) stop("must not read a secret")
  ))
})

testthat::test_that("SMTP uses fixed envelope addresses, UTF-8 and enforced TLS", {
  captured <- NULL
  transport <- function(...) {
    captured <<- list(...)
  }
  testthat::expect_true(app_functions$contact_send_mail(
    "Frage zu Thüringen",
    "person@example.net",
    "Grüße\nZweite Zeile",
    config = smtp_fixture(),
    transport = transport
  ))
  testthat::expect_identical(captured$mail_from, "kontakt@example.org")
  testthat::expect_identical(captured$mail_rcpt, "inbox@example.org")
  testthat::expect_identical(captured$use_ssl, "force")
  testthat::expect_true(captured$ssl_verifypeer)
  testthat::expect_identical(captured$ssl_verifyhost, 2L)
  testthat::expect_false(captured$verbose)
  testthat::expect_equal(captured$timeout, 10)
  testthat::expect_match(
    captured$message,
    "Reply-To: person@example.net",
    fixed = TRUE
  )
  testthat::expect_match(captured$message, "Subject: =?UTF-8?B?", fixed = TRUE)
  parts <- strsplit(captured$message, "\r\n\r\n", fixed = TRUE)[[1]]
  testthat::expect_identical(
    rawToChar(jsonlite::base64_dec(gsub("\r\n", "", parts[[2]], fixed = TRUE))),
    enc2utf8("Grüße\nZweite Zeile")
  )
  testthat::expect_lte(
    max(nchar(
      strsplit(captured$message, "\r\n", fixed = TRUE)[[1]],
      type = "bytes"
    )),
    78
  )
  testthat::expect_error(
    app_functions$contact_send_mail(
      "Frage\nBcc: other@example.org",
      "person@example.net",
      "Text",
      config = smtp_fixture(),
      transport = function(...) stop("must not send")
    ),
    "Ungültige Nachricht",
    fixed = TRUE
  )
})

testthat::test_that("valid submissions send once, remain throttled across dialogs", {
  calls <- list()
  clock <- 100
  server <- function(input, output, session) {
    app_functions$contact_server(
      input,
      session,
      output = output,
      show = function(...) NULL,
      config = smtp_fixture,
      now = function() clock,
      send = function(...) {
        calls[[length(calls) + 1L]] <<- list(...)
      }
    )
  }
  shiny::testServer(server, {
    session$setInputs(send_message = 1)
    testthat::expect_length(calls, 0)
    session$setInputs(
      message_subject = " Frage ",
      message_email = "person@example.net",
      message_text = " Text ",
      send_message = 2
    )
    testthat::expect_length(calls, 1)
    testthat::expect_identical(
      unname(calls[[1]][1:3]),
      list("Frage", "person@example.net", "Text")
    )
    testthat::expect_null(output$message_status)
    session$setInputs(show_message = 1, send_message = 3)
    testthat::expect_length(calls, 1)
    testthat::expect_match(
      output$message_status$html,
      "60 Sekunden",
      fixed = TRUE
    )
    clock <<- 160
    session$setInputs(send_message = 4)
    testthat::expect_length(calls, 2)
  })
})

testthat::test_that("SMTP errors are redacted and failed attempts are throttled", {
  calls <- 0L
  server <- function(input, output, session) {
    app_functions$contact_server(
      input,
      session,
      output = output,
      config = smtp_fixture,
      send = function(...) {
        calls <<- calls + 1L
        stop("secret credential and person@example.net")
      }
    )
  }
  shiny::testServer(server, {
    session$flushReact()
    session$setInputs(
      message_subject = "Frage",
      message_email = "person@example.net",
      message_text = "Text",
      send_message = 1
    )
    testthat::expect_equal(calls, 1L)
    testthat::expect_match(
      output$message_status$html,
      "nicht bestätigt",
      fixed = TRUE
    )
    testthat::expect_false(grepl(
      "secret|person@example.net",
      output$message_status$html
    ))
    session$setInputs(send_message = 2)
    testthat::expect_equal(calls, 1L)
  })
})
