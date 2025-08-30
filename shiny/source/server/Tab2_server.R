# query data
df2 <- reactive({
  con %>%
    tbl("Tagesdaten") %>%
    filter(
      Name_Station == input$selectLocation,
      DATUM == input$date2
      ) %>%
    collect()
})

# render description
output$description2 <- renderUI({
  HTML(
    paste0(
      "Diese Felder zeigen die Wetterdaten für den Standort ",
      "<strong>", input$selectLocation, "</strong>" ,
      " am ",
      "<strong>", format(input$date2, '%d.%m.%Y'), "</strong>",
      " an."
    )
  )
})

color_boxes <- "primary"

output$box1 <- renderValueBox({
  valueBox(value = if((nrow(df2())[1] == 0)){"Nicht\nverfuegbar"}
           else if (is.na(df2()$Lufttemperatur)) {"Nicht\nverfuegbar"}
           else h2((paste0(df2()$Lufttemperatur%>%round(1),"°C"))),
           subtitle = HTML(paste0("Durchschnittstemperatur",
                                  "<br>","am ", input$date2 %>% format("%d.%m.%Y")
           )),
           icon = tags$i(class = "fas fa-thermometer-half"),
           color = color_boxes)
})

output$box2 <- renderValueBox({
  valueBox(value = if((nrow(df2())[1] == 0)){"Nicht\nverfuegbar"}
           else if ( is.na(df2()$Lufttemperatur_Min)) {"Nicht\nverfuegbar"}
           else (h2(paste0(df2()$Lufttemperatur_Min%>%round(1),"°C"))),
           subtitle = HTML(paste0("Minimaltemperatur",
                                  "<br>","am ", input$date2%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-thermometer-empty"),
           color = color_boxes)
})

output$box3 <- renderValueBox({
  valueBox(value = if((nrow(df2())[1] == 0)){"Nicht\nverfuegbar"}
           else if ( is.na(df2()$Lufttemperatur_Max)) {"Nicht\nverfuegbar"}
           else (h2(paste0(df2()$Lufttemperatur_Max%>%round(1),"°C"))),
           subtitle = HTML(paste0("Maximaltemperatur",
                                  "<br>","am ", input$date2%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-thermometer-full"),
           color = color_boxes)
})

output$box4 <- renderValueBox({
  valueBox(value = if((nrow(df2())[1] == 0)){"Nicht\nverfuegbar"}
           else if ( is.na(df2()$Sonnenscheindauer)) {"Nicht\nverfuegbar"}
           else (h2(paste0(df2()$Sonnenscheindauer%>%round(1)," Stunden"))),
           subtitle = HTML(paste0("Sonnenscheindauer", "<br>","am ", input$date2%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-sun"),
           color = color_boxes)
})

output$box5 <- renderValueBox({
  valueBox(value = if((nrow(df2())[1] == 0)){"Nicht\nverfuegbar"}
           else if ( is.na(df2()$Niederschlagshoehe)) {"Nicht\nverfuegbar"}
           else (h2(paste0(df2()$Niederschlagshoehe%>%round(1)," mm"))),
           subtitle = HTML(paste0("Niederschlagshoehe", "<br>","am ", input$date2%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-umbrella"),
           color = color_boxes)
})

output$box6 <- renderValueBox({
  valueBox(value = if((nrow(df2())[1] == 0)){"Nicht\nverfuegbar"}
           else if ( is.na(df2()$Schneehoehe)) {"Nicht\nverfuegbar"}
           else (h2(paste0(df2()$Schneehoehe%>%round(1)," cm"))),
           subtitle = HTML(paste0("Schneehoehe", "<br>","am ", input$date2%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-snowflake"),
           color = color_boxes)
})

output$box7 <- renderValueBox({
  valueBox(value = if((nrow(df2())[1] == 0)){"Nicht\nverfuegbar"}
           else if ( is.na(df2()$Windgeschwindigkeit)) {"Nicht\nverfuegbar"}
           else (h2(paste0(df2()$Windgeschwindigkeit%>%round(1)," m/s"))),
           subtitle = HTML(paste0("Windgeschwindigkeit", "<br>","am ", input$date2%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-forward"),
           color = color_boxes)
})

output$box8 <- renderValueBox({
  valueBox(value = if((nrow(df2())[1] == 0)){"Nicht\nverfuegbar"}
           else if ( is.na(df2()$Windspitze)) {"Nicht\nverfuegbar"}
           else (h2(paste0(df2()$Windspitze%>%round(1)," m/s"))),
           subtitle = HTML(paste0("Windspitze", "<br>","am ", input$date2%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-long-arrow-alt-right"),
           color = color_boxes)
})

output$box9 <- renderValueBox({
  valueBox(value = if((nrow(df2())[1] == 0)){"Nicht\nverfuegbar"}
           else if ( is.na(df2()$Luftdruck)) {"Nicht\nverfuegbar"}
           else (h2(paste0(df2()$Luftdruck%>%round(1)," hpa"))),
           subtitle = HTML(paste0("Luftdruck (Tagesmittel)", "<br>","am ", input$date2%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-align-center"),
           color = color_boxes)
})

