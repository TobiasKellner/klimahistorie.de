function(input, output, session) {

  ns = session$ns

  # source server scripts
  source("source/server/Tab1_server.R", local = TRUE, encoding = "UTF-8")
  source("source/server/Tab7_server.R", local = TRUE, encoding = "UTF-8")

  # Kontrollleiste ein/ausblenden
  observeEvent(input$update_kontrollbar, { updateSidebar("controlbar") })




  observeEvent(input$button1, {
    showModal(modalDialog(
      title = HTML("<b>Schreiben Sie mir eine Nachricht!</b>"),
      HTML("<span style=\"font-family: Calibri, sans-serif;\"><strong><span style=\"font-size: 18px;\">Gerne unterstütze ich Sie bei Problemen und Herausforderungen in folgenden Bereichen:</span></strong></span>"),
      br(),
      br(),
      fluidRow(
        column(
          6,
          #img(src='image_graphics.jpg', height = "80%",width="100%"),
          div(class = "flip-container",
              div(class = "flipper",
                  div(class = "front",
                      img(src = "image_graphics.jpg", alt = "Bild", height = "100%",width="100%")
                  ),
                  div(class = "back",
                      HTML(
                        paste0(
                          "<p style=\"text-align: center;\"><strong>Fallbeispiel:</strong>", br(),
                          "Sie möchten den Umsatz Ihres Unternehmens über die letzten Jahre, ",
                          "inklusive der Untergliederung in verschiedene Geschäftsbereiche, ",
                          "visualisieren, um Wachstumsraten und saisonale Schwankungen darzustellen."
                        )
                      )
                  )
              )
          ),
          #br(),
          HTML("<span style=\"font-family: Calibri, sans-serif;\"><span style=\"font-size: 18px;\">Datenanalyse, Visualisierung & statistische Berechnungen</span></span>")),
        column(
          6,
          #img(src='image_reporting.jpg', height = "80%", width="100%"),
          div(class = "flip-container",
              div(class = "flipper",
                  div(class = "front",
                      img(src = "image_reporting.jpg", alt = "Bild", height = "100%",width="100%")
                  ),
                  div(class = "back",
                      HTML(
                        paste0(
                          "<p style=\"text-align: center;\"><strong>Fallbeispiel:</strong>", br(),
                          "Sie möchten Analysen von Verkaufszahlen, Marktsegmenten sowie Kundenverhalten erstellen ",
                          "und diese Daten in einem interaktiven Dashboard zusammenführen, ",
                          "um Trends zu identifizieren und Chancen zu erkennen."
                        )
                      )
                  )
              )
          ),
          #br(),
          HTML("<span style=\"font-family: Calibri, sans-serif;\"><span style=\"font-size: 18px;\">Berichte & Reportings<br>(Web-Anwendungen, Dashboards, PDF, Word, HTML)</span></span>")
      )
      ),
      br(),
      fluidRow(
        column(
          6,
          #img(src='image_automatization.jpg', height = "80%", width="100%"),
          div(class = "flip-container",
              div(class = "flipper",
                  div(class = "front",
                      img(src = "image_automatization.jpg", alt = "Bild", height = "100%",width="100%")
                  ),
                  div(class = "back",
                      HTML(
                        paste0(
                        "<p style=\"text-align: center;\"><strong>Fallbeispiel:</strong>", br(), "Sie möchten eine große Anzahl an ",
                        "Dokumenten, bspw. Rechnungen oder Berichte im PDF-Format, ",
                        "jeden Monat automatisiert erstellen und an Kunden per E-Mail schicken."
                        )
                      )
                  )
              )
          ),
          #br(),
          HTML("<span style=\"font-family: Calibri, sans-serif;\"><span style=\"font-size: 18px;\">Automatisierung von Datenprozessen & skalierbare Datenoperationen</span></span>")),
        column(
          6,
          #img(src='image_consulting.jpg', height = "80%", width="100%"),
          div(class = "flip-container",
              div(class = "flipper",
                  div(class = "front",
                      img(src = "image_consulting.jpg", alt = "Bild", height = "100%",width="100%")
                  ),
                  div(class = "back",
                      HTML(
                        paste0(
                          "<p style=\"text-align: center;\"><strong>Fallbeispiel:</strong>", br(),
                          "Sie möchten ",
                          "Daten aus verschiedenen Quellen verbinden und durch die Zusammenführung in einer Web-App ",
                          "Prozesse digitalisieren und Arbeitsaufwand senken."
                        )
                      )
                  )
              )
          ),
          #br(),
          HTML("<span style=\"font-family: Calibri, sans-serif;\"><span style=\"font-size: 18px;\">Beratung bei komplexen Datenprojekten & Unterstützung bei datenbasierten Entscheidungsprozessen</span></span>")
          )
      ),
      br(),
      br(),
      HTML(
        paste0(
          "<span style=\"font-family: Calibri, sans-serif;\"><strong><span style=\"font-size: 24px;\">",
          "E-Mail: ",
          a("Tobias.Kellner@protonmail.com", href = "mailto: Tobias.Kellner@protonmail.com"),
          "</span></strong></span>"
          )
        ),
      easyClose = TRUE,
      size = "l",
      footer = tagList(
        actionButton(
          "close1",
          "Schließen",
          style = "color: white ; background-color: #ec7063; border-radius: 10px; border: none;"
        )
      )
    ))
  })
  # ModalDialog schließen
  observeEvent(input$close1, {removeModal()})




  observeEvent(input$sidebarCollapsed, {
    if (input$sidebarCollapsed) {
      # Seitenleiste eingeklappt: Nur das Icon anzeigen
      updateActionButton(session, "button1", label = "", icon = tags$i(class = "fas fa-hand-pointer", style="font-size: 24px; color: white"))
    } else {
      # Seitenleiste ausgeklappt: Ursprüngliches Label und Icon anzeigen
      updateActionButton(
        session,
        "button1",
        label = HTML("Benötigen Sie Hilfe zu<br/>statistischen Auswertungen,<br/>Datenanalysen &<br/>Visualisierungen?"),
        icon = icon(""))
    }
  })





  output$mymap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(-93.65, 42.0285, zoom = 17) %>%
      addPopups(-93.65, 42.0285, 'Here is the <b>Department of Statistics</b>, ISU') %>%
      addMarkers(-93.65, 42.0285)
  })

}

