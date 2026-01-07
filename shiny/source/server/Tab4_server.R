# query data
df4 <- reactive({
  con %>%
    tbl("Tagesdaten") %>%
    filter(
      Name_Station == input$selectLocation,
      day(DATUM) == day(input$date_dayhistory),
      month(DATUM) == month(input$date_dayhistory)
      ) %>%
    collect()
})

# render description
output$description4 <- renderUI({
  HTML(
    paste0(
      "Diese Grafik zeigt die <strong>",
      input$variable_dayhistory,
      "</strong> für den Standort ",
      "<strong>",
      input$selectLocation,
      "</strong> an einem <strong>",
      format(input$date_dayhistory, "%d.%m."),
      "</strong> ",
      ifelse(
        input$sort4 == TRUE,
        paste0(
          "<u>absteigend nach</u> der ",
          input$variable_dayhistory,
          " an."
        ),
        " an."
      )
    )
  )
})

# render plot
output$plot_dayhistory <- renderPlotly({

  p2 <- df4() %>%
    mutate(Jahr = year(DATUM)) %>%
    arrange(Jahr) %>%
    `if`(
      input$sort4 == TRUE,
      arrange(., desc(!!sym(input$variable_dayhistory))),
      .
    ) %>%
    mutate(Jahr = factor(Jahr, levels = unique(Jahr))) %>%
    ggplot(
      aes(
        x = Jahr,
        y = !!sym(input$variable_dayhistory),
        fill = !!sym(input$variable_dayhistory),
        text = paste("Datum: ", format(DATUM, "%d.%m.%Y"), "<br>","Wetterstation: ", input$selectLocation)
        )
    ) +
    geom_bar(stat = 'identity', position = 'dodge') +
    scale_fill_gradient(
      low = case_when(
        input$variable_dayhistory == "Lufttemperatur" ~ "blue",
        input$variable_dayhistory == "Schneehoehe" ~ "green",
        input$variable_dayhistory == "Sonnenscheindauer" ~ "black",
        input$variable_dayhistory == "Niederschlagshoehe" ~ "brown"
      ),
      high = case_when(
        input$variable_dayhistory == "Lufttemperatur" ~ "red",
        input$variable_dayhistory == "Schneehoehe" ~ "blue",
        input$variable_dayhistory == "Sonnenscheindauer" ~ "yellow",
        input$variable_dayhistory == "Niederschlagshoehe" ~ "blue"
      )
    ) +
    xlab("Jahr")+
    ylab(
      paste0(
        input$variable_dayhistory,
        case_when(
          input$variable_dayhistory == "Lufttemperatur" ~ " in °C",
          input$variable_dayhistory == "Schneehoehe" ~ " in cm",
          input$variable_dayhistory == "Sonnenscheindauer" ~ " in Stunden/Tag",
          input$variable_dayhistory == "Niederschlagshoehe" ~ "in mm/m²"
        )
      )
    ) +
    theme(
      legend.position = "none",
      plot.background = element_rect(fill = 'transparent', color = NA),
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
    )

  ggplotly(if (input$average1) {
    print(p2+ geom_hline(yintercept = mean(df4() |> pull(input$variable_dayhistory), na.rm = TRUE), color="blue") )
  } else {p2}, tooltip = c("y", "text"))
})
