
df_stationstabelle <- reactive({
  con %>%
    tbl("Stationstabelle")%>%
    distinct(Stationsname, .keep_all = TRUE) %>%
    collect()
})


icon <- reactive({
  awesomeIcons(
  icon = 'circle',
  iconColor = '#FFFFFF',
  library = 'fa',
  spin = TRUE,
  markerColor = ifelse(df_stationstabelle()$Stationsname == input$selectLocation, 'red', 'blue'))
})

output$map_overview <- renderLeaflet({
  df_stationstabelle() %>%
    leaflet() %>%
    addTiles() %>%
    addAwesomeMarkers(
      lng = ~ geoLaenge,
      lat = ~ geoBreite,
      popup = ~ as.character(Stationsname),
      icon = icon(),
      layerId = ~ Stationsname,
      label = ~ lapply(
        str_c(
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
        ),
        HTML
      )
    )
})

observe({
  updateSelectInput(inputId = "selectLocation", selected = input$map_overview_marker_click$id)
})


