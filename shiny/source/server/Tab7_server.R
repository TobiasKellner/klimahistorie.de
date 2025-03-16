
df_stationstabelle <- reactive({
  con %>%
    tbl("Stationstabelle") %>%
    collect()
})


output$map_overview <- renderLeaflet({
  df_stationstabelle() %>%
    tibble()%>%
    distinct(Stationsname, .keep_all = TRUE)%>%
    leaflet() %>%
    addTiles() %>%
    addMarkers(
      lng = ~ geoLaenge,
      lat = ~ geoBreite,
      popup = ~ as.character(Stationsname),
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


