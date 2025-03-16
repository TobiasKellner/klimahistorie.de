# query data
df1 <- reactive({
  con %>%
    tbl("Tagesdaten") %>%
    {if(input$month1 != 0) filter(., sql("EXTRACT(MONTH FROM \"DATUM\")") == input$month1) else .} %>%
    filter(Name_Station == input$selectLocation) %>%
    {if(input$current_year == FALSE) filter(., DATUM <= as.Date("2024-12-31")) else .} %>%
    group_by(Jahr = year(DATUM)) %>%
    summarise(!!input$Variable1 := round(mean(!!sym(input$Variable1)), 1)) %>%
    collect()
})

# render plot
output$plot1 <- renderPlotly({

  ggplotly({
    p1 <- ggplot(
      data = df1(),
      mapping = aes(
        x = Jahr,
        y = !!sym(input$Variable1),
        fill = !!sym(input$Variable1),
        text = paste0("Wetterstation: ", input$selectLocation)
      )
      )+
      geom_bar(stat = "identity") +
      scale_fill_gradient(
        low = case_when(
          input$Variable1 == "Lufttemperatur" ~ "blue",
          input$Variable1 == "Schneehoehe" ~ "green",
          input$Variable1 == "Sonnenscheindauer" ~ "black",
          input$Variable1 == "Niederschlagshoehe" ~ "brown"
        ),
        high = case_when(
          input$Variable1 == "Lufttemperatur" ~ "red",
          input$Variable1 == "Schneehoehe" ~ "blue",
          input$Variable1 == "Sonnenscheindauer" ~ "yellow",
          input$Variable1 == "Niederschlagshoehe" ~ "blue"
        )
        )+
      xlab("Jahr")+
      ylab(
        paste0(
          input$Variable1,
          case_when(
            input$Variable1 == "Lufttemperatur" ~ " in °C",
            input$Variable1 == "Schneehoehe" ~ " in cm",
            input$Variable1 == "Sonnenscheindauer" ~ " in Stunden/Tag",
            input$Variable1 == "Niederschlagshoehe" ~ "in mm/m²"
          )
          )
        )+
      theme(
        legend.position = "none",
        plot.background = element_rect(fill = 'transparent', color = NA)
      )

    if(input$regline == TRUE) {
      print(p1+geom_smooth(method='lm', formula= y~x, se = FALSE))
      } else p1
  },
  tooltip=c("x", "y", "text")
  )

})

# render description
output$description1 <- renderUI({
  HTML(
    paste0(
      "Diese Grafik zeigt die durchschnittliche ",
      "<strong>", input$Variable1, "</strong> ",
      "am Standort ",
      "<strong>", input$selectLocation, "</strong> ",
      "für ",
      "<strong>",
      ifelse(
        input$month1 == 0,
        'das gesamte Jahr.',
        paste0("den Monat ", month_list %>% keep(~ .x == input$month1) %>% names(), ".")
        ),
      "</strong> "
      )
    )
})
