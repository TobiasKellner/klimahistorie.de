contact_card_ui <- function(
  title,
  image,
  example,
  image_class = "contact-image",
  overlay = FALSE,
  image_ratio = "3 / 2"
) {
  image_tag <- shiny::tags$img(src = image, alt = title, class = image_class)
  htmltools::tagAppendAttributes(
    bslib::card(
      if (overlay) {
        bslib::card_body(image_tag, class = "contact-card-image-layer")
      } else {
        image_tag
      },
      bslib::card_body(
        shiny::tags$h3(title, class = "h5"),
        shiny::tags$details(
          shiny::tags$summary("Fallbeispiel"),
          shiny::tags$p(example)
        )
      )
    ),
    class = if (overlay) "contact-card-overlay" else NULL,
    style = if (overlay) {
      paste0("--contact-image-ratio: ", image_ratio, ";")
    } else {
      NULL
    }
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
          col_widths = bslib::breakpoints(xs = 12, sm = 6),
          fill = FALSE,
          contact_card_ui(
            "Datenanalyse, Visualisierung & statistische Berechnungen",
            "image_data_analysis.png",
            paste0(
              "Sie möchten den Umsatz Ihres Unternehmens über die letzten Jahre, ",
              "inklusive der Untergliederung in verschiedene Geschäftsbereiche, ",
              "visualisieren, um Wachstumsraten und saisonale Schwankungen darzustellen."
            ),
            image_class = "contact-image contact-image-cover",
            overlay = TRUE,
            image_ratio = "1672 / 941"
          ),
          contact_card_ui(
            "Berichte & Reportings (Web-Anwendungen, Dashboards, PDF, Word, HTML)",
            "image_reporting.png",
            paste0(
              "Sie möchten Analysen von Verkaufszahlen, Marktsegmenten sowie Kundenverhalten erstellen ",
              "und diese Daten in einem interaktiven Dashboard zusammenführen, ",
              "um Trends zu identifizieren und Chancen zu erkennen."
            ),
            image_class = "contact-image contact-image-cover",
            overlay = TRUE
          ),
          contact_card_ui(
            "Automatisierung von Datenprozessen & skalierbare Datenoperationen",
            "image_automatization.png",
            paste0(
              "Sie möchten eine große Anzahl an ",
              "Dokumenten, bspw. Rechnungen oder Berichte im PDF-Format, ",
              "jeden Monat automatisiert erstellen und an Kunden per E-Mail schicken."
            ),
            image_class = "contact-image contact-image-cover",
            overlay = TRUE,
            image_ratio = "1672 / 941"
          ),
          contact_card_ui(
            "Beratung bei komplexen Datenprojekten & Unterstützung bei datenbasierten Entscheidungsprozessen",
            "image_consulting.png",
            paste0(
              "Sie möchten Daten aus verschiedenen Quellen verbinden und durch die Zusammenführung in einer Web-App ",
              "Prozesse digitalisieren und Arbeitsaufwand senken."
            ),
            image_class = "contact-image contact-image-cover",
            overlay = TRUE
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
      "Alle Felder sind Pflichtfelder. Ihre Angaben werden zur Bearbeitung ",
      "der Anfrage per E-Mail an den Betreiber übermittelt."
    ),
    shiny::textInput("message_subject", "Betreff", width = "100%"),
    htmltools::tagQuery(
      shiny::textInput("message_email", "Ihre E-Mail-Adresse", width = "100%")
    )$find("input")$removeAttrs("type")$addAttrs(
      type = "email",
      autocomplete = "email"
    )$allTags(),
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
      bslib::input_task_button(
        "send_message",
        "Nachricht senden",
        icon = shiny::icon("paper-plane"),
        label_busy = "Wird gesendet …",
        type = "primary"
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
  } else if (nchar(subject) > 200L || grepl("[[:cntrl:]]", subject)) {
    errors <- c(
      errors,
      "Der Betreff darf maximal 200 Zeichen enthalten und muss einzeilig sein."
    )
  }
  if (
    !nzchar(email) ||
      nchar(email) > 254L ||
      grepl("[[:cntrl:]]", email) ||
      !grepl(
        "^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)+$",
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
  output = session$output,
  send = contact_send_mail,
  config = contact_smtp_config,
  now = function() as.numeric(Sys.time()),
  notify = shiny::showNotification,
  close = shiny::removeModal
) {
  status <- shiny::reactiveVal(NULL)
  last_attempt <- -Inf
  shiny::observeEvent(
    status(),
    {
      result <- status()
      notify(
        paste(result$text, collapse = " "),
        type = switch(
          result$class,
          "alert-success" = "message",
          "alert-danger" = "error",
          "warning"
        ),
        duration = 10,
        session = session
      )
    },
    ignoreNULL = TRUE
  )
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
      if (length(errors)) {
        status(list(class = "alert-danger", text = errors))
        return()
      }
      if (now() - last_attempt < 60) {
        status(list(
          class = "alert-warning",
          text = "Bitte warten Sie 60 Sekunden zwischen Versandversuchen."
        ))
        return()
      }
      last_attempt <<- now()
      result <- tryCatch(
        {
          settings <- config()
          if (is.null(settings)) {
            list(
              class = "alert-warning",
              text = "Der E-Mail-Versand ist derzeit deaktiviert. Ihre Nachricht wurde nicht gesendet."
            )
          } else {
            send(
              trimws(input$message_subject),
              trimws(input$message_email),
              trimws(input$message_text),
              config = settings
            )
            list(
              class = "alert-success",
              text = "Ihre Nachricht wurde erfolgreich versendet."
            )
          }
        },
        error = function(e) {
          # Provider errors may contain addresses or credentials; do not expose them.
          list(
            class = "alert-danger",
            text = "Der Versand konnte nicht bestätigt werden. Bitte versuchen Sie es später erneut."
          )
        }
      )
      if (identical(result$class, "alert-success")) {
        status(NULL)
        close(session = session)
        notify(
          shiny::tagList(
            shiny::icon("circle-check"),
            result$text
          ),
          type = "message",
          duration = 10,
          session = session
        )
      } else {
        status(result)
      }
    },
    ignoreInit = TRUE
  )
}
