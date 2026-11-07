contact_card_ui <- function(title, image, example) {
  bslib::card(
    shiny::tags$img(src = image, alt = title, class = "contact-image"),
    bslib::card_body(
      shiny::tags$h3(title, class = "h5"),
      shiny::tags$details(
        shiny::tags$summary("Fallbeispiel"),
        shiny::tags$p(example)
      )
    )
  )
}

contact_modal_ui <- function() {
  htmltools::tagAppendAttributes(
    shiny::modalDialog(
      title = "Schreiben Sie mir eine Nachricht!",
      shiny::tags$div(
        class = "contact-advertising",
        shiny::tags$p(shiny::tags$strong(
          "Gerne unterstütze ich Sie bei Problemen und Herausforderungen in folgenden Bereichen:"
        )),
        bslib::layout_columns(
          col_widths = c(6, 6, 6, 6),
          fill = FALSE,
          contact_card_ui(
            "Datenanalyse, Visualisierung & statistische Berechnungen",
            "image_graphics.jpg",
            paste0(
              "Sie möchten den Umsatz Ihres Unternehmens über die letzten Jahre, ",
              "inklusive der Untergliederung in verschiedene Geschäftsbereiche, ",
              "visualisieren, um Wachstumsraten und saisonale Schwankungen darzustellen."
            )
          ),
          contact_card_ui(
            "Berichte & Reportings (Web-Anwendungen, Dashboards, PDF, Word, HTML)",
            "image_reporting.jpg",
            paste0(
              "Sie möchten Analysen von Verkaufszahlen, Marktsegmenten sowie Kundenverhalten erstellen ",
              "und diese Daten in einem interaktiven Dashboard zusammenführen, ",
              "um Trends zu identifizieren und Chancen zu erkennen."
            )
          ),
          contact_card_ui(
            "Automatisierung von Datenprozessen & skalierbare Datenoperationen",
            "image_automatization.jpg",
            paste0(
              "Sie möchten eine große Anzahl an ",
              "Dokumenten, bspw. Rechnungen oder Berichte im PDF-Format, ",
              "jeden Monat automatisiert erstellen und an Kunden per E-Mail schicken."
            )
          ),
          contact_card_ui(
            "Beratung bei komplexen Datenprojekten & Unterstützung bei datenbasierten Entscheidungsprozessen",
            "image_consulting.jpg",
            paste0(
              "Sie möchten Daten aus verschiedenen Quellen verbinden und durch die Zusammenführung in einer Web-App ",
              "Prozesse digitalisieren und Arbeitsaufwand senken."
            )
          )
        )
      ),
      easyClose = TRUE,
      size = "l",
      footer = shiny::tagList(
        shiny::modalButton("Abbrechen", icon = shiny::icon("xmark")),
        shiny::actionButton(
          "show_message",
          "Nachricht",
          icon = shiny::icon("envelope"),
          class = "btn-primary"
        )
      )
    ),
    class = "contact-modal"
  )
}

message_modal_ui <- function() {
  shiny::modalDialog(
    title = "Nachricht",
    shiny::tags$p(
      "Alle Felder sind Pflichtfelder. Der E-Mail-Versand ist noch nicht eingerichtet."
    ),
    shiny::textInput("message_subject", "Betreff", width = "100%"),
    htmltools::tagQuery(
      shiny::textInput("message_email", "Ihre E-Mail-Adresse", width = "100%")
    )$find("input")$addAttrs(type = "email", autocomplete = "email")$allTags(),
    shiny::textAreaInput(
      "message_text",
      "Ihre Nachricht",
      rows = 6,
      width = "100%"
    ),
    shiny::uiOutput("message_status", `aria-live` = "polite"),
    easyClose = FALSE,
    footer = shiny::tagList(
      shiny::modalButton("Abbrechen", icon = shiny::icon("xmark")),
      shiny::actionButton(
        "send_message",
        "Nachricht senden",
        icon = shiny::icon("paper-plane"),
        class = "btn-primary"
      )
    )
  )
}

message_validation_errors <- function(subject, email, text) {
  values <- lapply(list(subject, email, text), function(value) {
    if (is.null(value) || length(value) != 1L || is.na(value)) {
      ""
    } else {
      trimws(value)
    }
  })
  subject <- values[[1]]
  email <- values[[2]]
  text <- values[[3]]
  errors <- character()
  if (!nzchar(subject)) {
    errors <- c(errors, "Bitte geben Sie einen Betreff ein.")
  } else if (nchar(subject) > 200L || grepl("[\r\n]", subject)) {
    errors <- c(
      errors,
      "Der Betreff darf maximal 200 Zeichen enthalten und muss einzeilig sein."
    )
  }
  if (
    !nzchar(email) ||
      nchar(email) > 254L ||
      !grepl(
        "^[^[:space:]@<>]+@[^[:space:]@<>.]+(\\.[^[:space:]@<>.]+)+$",
        email
      )
  ) {
    errors <- c(errors, "Bitte geben Sie eine gültige E-Mail-Adresse ein.")
  }
  if (!nzchar(text)) {
    errors <- c(errors, "Bitte geben Sie eine Nachricht ein.")
  } else if (nchar(text) > 10000L) {
    errors <- c(errors, "Die Nachricht darf maximal 10.000 Zeichen enthalten.")
  }
  errors
}

contact_server <- function(
  input,
  session,
  show = shiny::showModal,
  output = session$output
) {
  status <- shiny::reactiveVal(NULL)
  output$message_status <- shiny::renderUI({
    result <- status()
    if (is.null(result)) {
      return(NULL)
    }
    shiny::tags$div(
      class = paste("alert", result$class),
      lapply(result$text, shiny::tags$p)
    )
  })
  shiny::observeEvent(
    input$show_contact,
    {
      show(contact_modal_ui(), session = session)
    },
    ignoreInit = TRUE
  )
  shiny::observeEvent(
    input$show_message,
    {
      # Shiny replaces the existing modal rather than stacking dialogs.
      status(NULL)
      show(message_modal_ui(), session = session)
    },
    ignoreInit = TRUE
  )
  shiny::observeEvent(
    input$send_message,
    {
      errors <- message_validation_errors(
        input$message_subject,
        input$message_email,
        input$message_text
      )
      status(
        if (length(errors)) {
          list(class = "alert-danger", text = errors)
        } else {
          list(
            class = "alert-warning",
            text = "Die Eingaben sind gültig. Der E-Mail-Versand ist noch nicht eingerichtet. Ihre Nachricht wurde nicht gesendet oder gespeichert."
          )
        }
      )
    },
    ignoreInit = TRUE
  )
}
