
output$map_overview <- renderLeaflet({
  Index_Wetterstationen%>%
    tibble()%>%
    filter(res=="daily")%>%
    distinct(Stationsname, .keep_all = TRUE)%>%
    filter(Stationsname %in% Liste)%>%
    leaflet() %>%
    addTiles() %>%
    addMarkers(
      ~ geoLaenge,
      ~ geoBreite,
      popup = ~ as.character(Stationsname),
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
          Stations_id,
          "</p>"
        ),
        HTML
      )
    )
})
