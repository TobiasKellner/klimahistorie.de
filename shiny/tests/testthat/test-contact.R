testthat::test_that("the sidebar contains a contact action button", {
  html <- htmltools::renderTags(app_functions$navigation_sidebar_ui())$html
  testthat::expect_match(html, 'id="show_contact"', fixed = TRUE)
  testthat::expect_match(html, "sidebar-contact", fixed = TRUE)
  testthat::expect_match(
    html,
    "<strong>Werbung in eigener Sache:</strong>",
    fixed = TRUE
  )
})

testthat::test_that("the contact modal includes advertising images without a mailto link", {
  html <- htmltools::renderTags(app_functions$contact_modal_ui())$html
  for (image in c(
    "image_graphics.jpg",
    "image_reporting.jpg",
    "image_automatization.jpg",
    "image_consulting.jpg"
  )) {
    testthat::expect_match(html, image, fixed = TRUE)
    testthat::expect_true(file.exists(file.path(app_dir, "www", image)))
  }
  testthat::expect_false(grepl("mailto:", html, fixed = TRUE))
  testthat::expect_match(html, "Abbrechen", fixed = TRUE)
  testthat::expect_match(html, "fa-xmark", fixed = TRUE)
  testthat::expect_match(html, 'id="show_message"', fixed = TRUE)
  testthat::expect_match(html, "fa-envelope", fixed = TRUE)
  testthat::expect_length(
    regmatches(html, gregexpr("<details>", html))[[1]],
    4L
  )
})

testthat::test_that("clicking contact opens the modal, not on initialization", {
  calls <- list()
  server <- function(input, output, session) {
    app_functions$contact_server(input, session, show = function(ui, session) {
      calls[[length(calls) + 1L]] <<- ui
    })
  }
  shiny::testServer(server, {
    session$flushReact()
    testthat::expect_length(calls, 0L)
    session$setInputs(show_contact = 1)
    testthat::expect_length(calls, 1L)
    session$setInputs(show_contact = 2)
    testthat::expect_length(calls, 2L)
    session$setInputs(show_message = 1)
    testthat::expect_length(calls, 3L)
    message_html <- htmltools::renderTags(calls[[3]])$html
    testthat::expect_match(message_html, "Nachricht", fixed = TRUE)
    testthat::expect_match(message_html, "fa-xmark", fixed = TRUE)
    for (id in c(
      "message_subject",
      "message_email",
      "message_text",
      "send_message"
    )) {
      testthat::expect_match(
        message_html,
        paste0('id="', id, '"'),
        fixed = TRUE
      )
    }
    testthat::expect_match(message_html, "Nachricht senden", fixed = TRUE)
    testthat::expect_false(grepl(
      "contact-advertising",
      message_html,
      fixed = TRUE
    ))
  })
})

testthat::test_that("message validation handles missing and malformed inputs", {
  validate <- app_functions$message_validation_errors
  testthat::expect_length(validate(NULL, NULL, NULL), 3L)
  testthat::expect_length(validate("  ", " ", "\n"), 3L)
  testthat::expect_length(
    validate("Frage", "person@example.org", "Meine Nachricht"),
    0L
  )
  testthat::expect_length(validate("Frage", "person", "Text"), 1L)
  testthat::expect_length(
    validate("Frage", "person@example.org\nBcc: other@example.org", "Text"),
    1L
  )
  testthat::expect_length(
    validate("Frage\nBcc: other", "person@example.org", "Text"),
    1L
  )
  testthat::expect_length(
    validate(strrep("a", 201), "person@example.org", strrep("a", 10001)),
    2L
  )
})

testthat::test_that("send validates without reporting a successful delivery", {
  server <- function(input, output, session) {
    app_functions$contact_server(input, session, output = output)
  }
  shiny::testServer(server, {
    session$flushReact()
    session$setInputs(send_message = 1)
    testthat::expect_match(
      output$message_status$html,
      "Bitte geben Sie einen Betreff ein.",
      fixed = TRUE
    )
    session$setInputs(
      message_subject = "Frage",
      message_email = "person@example.org",
      message_text = "Meine Nachricht",
      send_message = 2
    )
    testthat::expect_match(
      output$message_status$html,
      "nicht gesendet oder gespeichert",
      fixed = TRUE
    )
  })
})
