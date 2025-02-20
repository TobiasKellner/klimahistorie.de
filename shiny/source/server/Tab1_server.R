# query data
df1 <- reactive({
  con %>%
    tbl("Tagesdaten") %>%
    filter(Name_Station == "Augsburg") %>%
    group_by(Jahr = year(DATUM)) %>%
    summarise(Lufttemperatur = mean(Lufttemperatur) %>% round(1)) %>%
    collect()
})

# render plot
output$plot1 <- renderPlotly({

  ggplotly({
    ggplot(data = df1(), mapping = aes(x = Jahr, y = Lufttemperatur, fill = Lufttemperatur))+
      geom_bar(stat = "identity") +
      scale_fill_gradient(low = "blue", high = "red")+
      xlab("Jahr") +
      theme(
        legend.position = "none",
        plot.background = element_rect(fill='transparent', color=NA)
      )
  })

})
