function(input, output, session) {
  ns <- session$ns

  # source server scripts
  source("source/server/Tab1_server.R", local = TRUE, encoding = "UTF-8")
  source("source/server/Tab2_server.R", local = TRUE, encoding = "UTF-8")
  source("source/server/Tab3_server.R", local = TRUE, encoding = "UTF-8")
  source("source/server/Tab4_server.R", local = TRUE, encoding = "UTF-8")
  source("source/server/Tab5_server.R", local = TRUE, encoding = "UTF-8")
  source("source/server/Tab6_server.R", local = TRUE, encoding = "UTF-8")
  source("source/server/Tab7_server.R", local = TRUE, encoding = "UTF-8")

  # Werbe-modalDialog einblenden
  observeEvent(input$button1, {
    showModal(modalDialog(
      title = HTML("<b>Schreiben Sie mir eine Nachricht!</b>"),
      HTML(
        paste0(
          "<span style=\"font-family: Calibri, sans-serif;\">",
          "<strong><span style=\"font-size: 18px;\">",
          "Gerne unterstütze ich Sie bei Problemen und Herausforderungen in ",
          "folgenden Bereichen:</span></strong></span>"
        )
      ),
      br(),
      br(),
      fluidRow(
        column(
          6,
          #img(src='image_graphics.jpg', height = "80%",width="100%"),
          div(
            class = "flip-container",
            div(
              class = "flipper",
              div(
                class = "front",
                img(
                  src = "image_graphics.jpg",
                  alt = "Bild",
                  height = "100%",
                  width = "100%"
                )
              ),
              div(
                class = "back",
                HTML(
                  paste0(
                    "<p style=\"text-align: center;\"><strong>Fallbeispiel:</strong>",
                    br(),
                    "Sie möchten den Umsatz Ihres Unternehmens über die letzten Jahre, ",
                    "inklusive der Untergliederung in verschiedene Geschäftsbereiche, ",
                    "visualisieren, um Wachstumsraten und saisonale Schwankungen darzustellen."
                  )
                )
              )
            )
          ),
          HTML(
            paste0(
              "<span style=\"font-family: Calibri, sans-serif;\">",
              "<span style=\"font-size: 18px;\">",
              "Datenanalyse, Visualisierung & statistische Berechnungen</span>",
              "</span>"
            )
          )
        ),
        column(
          6,
          div(
            class = "flip-container",
            div(
              class = "flipper",
              div(
                class = "front",
                img(
                  src = "image_reporting.jpg",
                  alt = "Bild",
                  height = "100%",
                  width = "100%"
                )
              ),
              div(
                class = "back",
                HTML(
                  paste0(
                    "<p style=\"text-align: center;\"><strong>Fallbeispiel:</strong>",
                    br(),
                    "Sie möchten Analysen von Verkaufszahlen, Marktsegmenten sowie Kundenverhalten erstellen ",
                    "und diese Daten in einem interaktiven Dashboard zusammenführen, ",
                    "um Trends zu identifizieren und Chancen zu erkennen."
                  )
                )
              )
            )
          ),
          HTML(
            "<span style=\"font-family: Calibri, sans-serif;\"><span style=\"font-size: 18px;\">Berichte & Reportings<br>(Web-Anwendungen, Dashboards, PDF, Word, HTML)</span></span>"
          )
        )
      ),
      br(),
      fluidRow(
        column(
          6,
          div(
            class = "flip-container",
            div(
              class = "flipper",
              div(
                class = "front",
                img(
                  src = "image_automatization.jpg",
                  alt = "Bild",
                  height = "100%",
                  width = "100%"
                )
              ),
              div(
                class = "back",
                HTML(
                  paste0(
                    "<p style=\"text-align: center;\"><strong>Fallbeispiel:</strong>",
                    br(),
                    "Sie möchten eine große Anzahl an ",
                    "Dokumenten, bspw. Rechnungen oder Berichte im PDF-Format, ",
                    "jeden Monat automatisiert erstellen und an Kunden per E-Mail schicken."
                  )
                )
              )
            )
          ),
          HTML(
            "<span style=\"font-family: Calibri, sans-serif;\"><span style=\"font-size: 18px;\">Automatisierung von Datenprozessen & skalierbare Datenoperationen</span></span>"
          )
        ),
        column(
          6,
          div(
            class = "flip-container",
            div(
              class = "flipper",
              div(
                class = "front",
                img(
                  src = "image_consulting.jpg",
                  alt = "Bild",
                  height = "100%",
                  width = "100%"
                )
              ),
              div(
                class = "back",
                HTML(
                  paste0(
                    "<p style=\"text-align: center;\"><strong>Fallbeispiel:</strong>",
                    br(),
                    "Sie möchten ",
                    "Daten aus verschiedenen Quellen verbinden und durch die Zusammenführung in einer Web-App ",
                    "Prozesse digitalisieren und Arbeitsaufwand senken."
                  )
                )
              )
            )
          ),
          HTML(
            "<span style=\"font-family: Calibri, sans-serif;\"><span style=\"font-size: 18px;\">Beratung bei komplexen Datenprojekten & Unterstützung bei datenbasierten Entscheidungsprozessen</span></span>"
          )
        )
      ),
      easyClose = TRUE,
      size = "l",
      footer = tagList(
        actionButton(
          "close1",
          "Schließen",
          #icon = icon("xmark"),
          style = "color: white ; background-color: #ec7063; border-radius: 10px; border: none;"
        )
      )
    ))
  })

  # ModalDialog schließen
  observeEvent(input$close1, {
    removeModal()
  })

  # Karte der ausgewählten Wetterstation der sidebar rendern
  output$mymap <- renderLeaflet({
    req(
      !is.null(con),
      DBI::dbIsValid(con),
      input$selectLocation != "Keine Station verfügbar"
    )

    con %>%
      tbl("Stationstabelle") %>%
      filter(Stationsname == input$selectLocation) %>%
      collect() %>%
      leaflet() %>%
      addTiles() %>%
      addMarkers(
        ~geoLaenge,
        ~geoBreite,
        popup = ~Stationsname,
        label = ~ str_c(
          "<p>",
          "<b>",
          Stationsname,
          "</b>",
          " <p> ",
          "Bundesland: ",
          Bundesland,
          " <p> ",
          "Stationshoehe: ",
          Stationshoehe,
          " m",
          " <p> ",
          "Stations_id: ",
          STATIONS_ID,
          "</p>"
        ) %>%
          HTML()
      )
  })
}
