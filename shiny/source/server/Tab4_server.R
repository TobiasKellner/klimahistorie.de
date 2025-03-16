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
    `if`(
      input$sort4 == TRUE,
      arrange(., desc(!!sym(input$variable_dayhistory))),
      .
    ) %>%
    mutate(
      Jahr = year(DATUM),
      Jahr = factor(Jahr, levels = unique(Jahr))
    ) %>%
    ggplot(
      aes_string(x = "Jahr", y = input$variable_dayhistory, fill = input$variable_dayhistory)
    ) +
    geom_bar(stat = 'identity', position = 'dodge') +
    scale_fill_gradient(low = "blue", high = "red") +
    xlab("Jahr") +
    theme(
      legend.position = "none",
      plot.background = element_rect(fill = 'transparent', color = NA),
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
    )

  ggplotly(if (input$average1) {
    print(p2+ geom_hline(yintercept = mean(df4() |> pull(input$variable_dayhistory), na.rm = TRUE), color="blue") )
  } else {p2})
})
