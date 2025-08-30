# query data
df5 <- reactive({
  con %>%
    tbl("Tagesdaten") %>%
    filter(
      Name_Station == input$selectLocation
    ) %>%
    collect()
})

# render description
output$description5 <- renderUI({
  HTML(
    paste0(
      "Diese Felder zeigen den ",
      ifelse(
        input$record == "Maximum",
        "<strong>höchsten</strong>",
        "<strong>niedrigsten</strong>"
        ),
      " je gemessenen Wert der jeweiligen Wettervariable für den Standort ",
      "<strong>", input$selectLocation, "</strong>",
      "."
    )
  )
})

# render boxes
output$records_durchschnittstemperatur <- renderValueBox({
  valueBox(value = (if((nrow(df5())[1] == 0)){"Nicht\nverfuegbar"}
           else if(input$record=="Maximum")
             paste0(
               df5()$Lufttemperatur%>%
                 max(na.rm = T)%>%round(1),"°C")
           else if(input$record=="Minimum")
             paste0(
               df5()$Lufttemperatur%>%
                 min(na.rm = T)%>%round(1),"°C")) %>% h2(),
           subtitle = if(input$record=="Maximum")
             HTML(paste0("Durchschnittstemperatur",
                         "<br>",df5()[which.max(df5()$Lufttemperatur),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.max(df5()$Lufttemperatur),]$DATUM%>%format("%d.%m.%Y")))
           else if(input$record=="Minimum")
             HTML(paste0("Durchschnittstemperatur",
                         "<br>",df5()[which.min(df5()$Lufttemperatur),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.min(df5()$Lufttemperatur),]$DATUM%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-thermometer-half"),
           color = "primary"
  )
})

output$records_minimaltemperatur <- renderValueBox({
  valueBox(value = (if((nrow(df5())[1] == 0)){"Nicht\nverfuegbar"}
           else if(input$record=="Maximum")
             paste0(
               df5()$Lufttemperatur_Min%>%
                 max(na.rm = T)%>%round(1),"°C")
           else if(input$record=="Minimum")
             paste0(
               df5()$Lufttemperatur_Min%>%
                 min(na.rm = T)%>%round(1),"°C")) %>% h2(),
           subtitle = if(input$record=="Maximum")
             HTML(paste0("Minimaltemperatur",
                         "<br>",df5()[which.max(df5()$Lufttemperatur_Min),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.max(df5()$Lufttemperatur_Min),]$DATUM%>%format("%d.%m.%Y")))
           else if(input$record=="Minimum")
             HTML(paste0("Minimaltemperatur",
                         "<br>",df5()[which.min(df5()$Lufttemperatur_Min),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.min(df5()$Lufttemperatur_Min),]$DATUM%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-thermometer-empty"),
           color = "primary"
  )
})

output$records_maximaltemperatur <- renderValueBox({
  valueBox(value = (if((nrow(df5())[1] == 0)){"Nicht\nverfuegbar"}
           else if(input$record=="Maximum")
             paste0(
               df5()$Lufttemperatur_Max%>%
                 max(na.rm = T)%>%round(1),"°C")
           else if(input$record=="Minimum")
             paste0(
               df5()$Lufttemperatur_Max%>%
                 min(na.rm = T)%>%round(1),"°C")) %>% h2(),
           subtitle = if(input$record=="Maximum")
             HTML(paste0("Maximaltemperatur",
                         "<br>",df5()[which.max(df5()$Lufttemperatur_Max),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.max(df5()$Lufttemperatur_Max),]$DATUM%>%format("%d.%m.%Y")))
           else if(input$record=="Minimum")
             HTML(paste0("Maximaltemperatur",
                         "<br>",df5()[which.min(df5()$Lufttemperatur_Max),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.min(df5()$Lufttemperatur_Max),]$DATUM%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-thermometer-full"),
           color = "primary"
  )
})

output$records_sonnenscheindauer <- renderValueBox({
  valueBox(value = (if((nrow(df5())[1] == 0)){"Nicht\nverfuegbar"}
           else if(input$record=="Maximum")
             paste0(
               df5()$Sonnenscheindauer%>%
                 max(na.rm = T)%>%round(1)," Stunden")
           else if(input$record=="Minimum")
             paste0(
               df5()$Sonnenscheindauer%>%
                 min(na.rm = T)%>%round(1), " Stunden")) %>% h2(),
           subtitle = if(input$record=="Maximum")
             HTML(paste0("Sonnenscheindauer",
                         "<br>",df5()[which.max(df5()$Sonnenscheindauer),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.max(df5()$Sonnenscheindauer),]$DATUM%>%format("%d.%m.%Y")))
           else if(input$record=="Minimum")
             HTML(paste0("Sonnenscheindauer",
                         "<br>",df5()[which.min(df5()$Sonnenscheindauer),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.min(df5()$Sonnenscheindauer),]$DATUM%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-sun"),
           color = "primary"
  )
})

output$records_niederschlagshoehe <- renderValueBox({
  valueBox(value = (if((nrow(df5())[1] == 0)){"Nicht\nverfuegbar"}
           else if(input$record=="Maximum")
             paste0(
               df5()$Niederschlagshoehe%>%
                 max(na.rm = T)%>%round(1)," mm")
           else if(input$record=="Minimum")
             paste0(
               df5()$Niederschlagshoehe%>%
                 min(na.rm = T)%>%round(1)," mm")) %>% h2(),
           subtitle = if(input$record=="Maximum")
             HTML(paste0("Niederschlagshöhe",
                         "<br>",df5()[which.max(df5()$Niederschlagshoehe),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.max(df5()$Niederschlagshoehe),]$DATUM%>%format("%d.%m.%Y")))
           else if(input$record=="Minimum")
             HTML(paste0("Niederschlagshöhe",
                         "<br>",df5()[which.min(df5()$Niederschlagshoehe),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.min(df5()$Niederschlagshoehe),]$DATUM%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-umbrella"),
           color = "primary"
  )
})

output$records_schneehoehe <- renderValueBox({
  valueBox(value = (if((nrow(df5())[1] == 0)){"Nicht\nverfuegbar"}
           else if(input$record=="Maximum")
             paste0(
               df5()$Schneehoehe%>%
                 max(na.rm = T)%>%round(1)," cm")
           else if(input$record=="Minimum")
             paste0(
               df5()$Schneehoehe%>%
                 min(na.rm = T)%>%round(1)," cm")) %>% h2(),
           subtitle = if(input$record=="Maximum")
             HTML(paste0("Schneehöhe",
                         "<br>",df5()[which.max(df5()$Schneehoehe),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.max(df5()$Schneehoehe),]$DATUM%>%format("%d.%m.%Y")))
           else if(input$record=="Minimum")
             HTML(paste0("Schneehöhe",
                         "<br>",df5()[which.min(df5()$Schneehoehe),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.min(df5()$Schneehoehe),]$DATUM%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-snowflake"),
           color = "primary"
  )
})

output$records_windgeschwindigkeit <- renderValueBox({
  valueBox(value = (if((nrow(df5())[1] == 0)){"Nicht\nverfuegbar"}
           else if(input$record=="Maximum")
             paste0(
               df5()$Windgeschwindigkeit%>%
                 max(na.rm = T)%>%round(1)," m/s")
           else if(input$record=="Minimum")
             paste0(
               df5()$Windgeschwindigkeit%>%
                 min(na.rm = T)%>%round(1)," m/s")) %>% h2(),
           subtitle = if(input$record=="Maximum")
             HTML(paste0("Windgeschwindigkeit",
                         "<br>",df5()[which.max(df5()$Windgeschwindigkeit),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.max(df5()$Windgeschwindigkeit),]$DATUM%>%format("%d.%m.%Y")))
           else if(input$record=="Minimum")
             HTML(paste0("Windgeschwindigkeit",
                         "<br>",df5()[which.min(df5()$Windgeschwindigkeit),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.min(df5()$Windgeschwindigkeit),]$DATUM%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-forward"),
           color = "primary"
  )
})

output$records_windspitze <- renderValueBox({
  valueBox(value = (if((nrow(df5())[1] == 0)){"Nicht\nverfuegbar"}
           else if(input$record=="Maximum")
             paste0(
               df5()$Windspitze%>%
                 max(na.rm = T)%>%round(1)," m/s")
           else if(input$record=="Minimum")
             paste0(
               df5()$Windspitze%>%
                 min(na.rm = T)%>%round(1)," m/s")) %>% h2(),
           subtitle = if(input$record=="Maximum")
             HTML(paste0("Windspitze",
                         "<br>",df5()[which.max(df5()$Windspitze),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.max(df5()$Windspitze),]$DATUM%>%format("%d.%m.%Y")))
           else if(input$record=="Minimum")
             HTML(paste0("Windspitze",
                         "<br>",df5()[which.min(df5()$Windspitze),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.min(df5()$Windspitze),]$DATUM%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-long-arrow-alt-right"),
           color = "primary"
  )
})

output$records_luftdruck <- renderValueBox({
  valueBox(value = (if((nrow(df5())[1] == 0)){"Nicht\nverfuegbar"}
           else if(input$record=="Maximum")
             paste0(
               df5()$Luftdruck%>%
                 max(na.rm = T)%>%round(1)," hpa")
           else if(input$record=="Minimum")
             paste0(
               df5()$Luftdruck%>%
                 min(na.rm = T)%>%round(1)," hpa")) %>% h2(),
           subtitle = if(input$record=="Maximum")
             HTML(paste0("Luftdruck",
                         "<br>",df5()[which.max(df5()$Luftdruck),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.max(df5()$Luftdruck),]$DATUM%>%format("%d.%m.%Y")))
           else if(input$record=="Minimum")
             HTML(paste0("Luftdruck",
                         "<br>",df5()[which.min(df5()$Luftdruck),]$Name_Station,
                         "<br>",
                         "am ",
                         df5()[which.min(df5()$Luftdruck),]$DATUM%>%format("%d.%m.%Y"))),
           icon = tags$i(class = "fas fa-align-center"),
           color = "primary"
  )
})
