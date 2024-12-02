server <- function(input, output, session) {

  ns = session$ns

  # Kontrollleiste ein/ausblenden
  observeEvent(input$update_kontrollbar, { updateSidebar("controlbar") })




  observeEvent(input$button1, {
    showModal(modalDialog(
      title = HTML("<b>Schreiben Sie mir eine Nachricht!</b>"),
      HTML(
        paste0(
          "Gerne unterstütze ich Sie in den Bereichen:<br/> <ul>",
          "<li>Datenanalyse</li>",
          "<li>Datenvisualisierung</li>",
          "<li>Datenbearbeitung</li>",
          "<li>Statistik</li>",
          "<li>Reportings</li>",
          "<li>Automatisierung von Datenprozessen</li>",
          "<li>Beratung</li></ul>"
        )
      ),
      "E-Mail: ",
      a("Tobias.Kellner@protonmail.com",
        href = "mailto: Tobias.Kellner@protonmail.com"),
      easyClose = TRUE,
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

}
