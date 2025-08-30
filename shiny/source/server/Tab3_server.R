# query data
df3 <- reactive({

  year_vector <- strsplit(input$year3, ",")[[1]]

  con %>%
    tbl("Tagesdaten") %>%
    {if(input$month3 != 0) filter(., sql("EXTRACT(MONTH FROM \"DATUM\")") == input$month1) else .} %>%
    filter(Name_Station == input$selectLocation) %>%
    # filter(year(DATUM) %in% year_vector) %>%
    #{if(input$current_year == FALSE) filter(., DATUM <= as.Date("2024-12-31")) else .} %>%
    #group_by(Jahr = year(DATUM)) %>%
    #summarise(!!input$Variable1 := round(mean(!!sym(input$Variable1)), 1)) %>%
    collect()%>%
    mutate(Jahr = factor(year(DATUM)),
           date = update(DATUM, year = 1))
})

# render plot
output$plot3 <- renderPlotly({

  req(input$selectLocation)

  year_vector <- strsplit(input$year3, ",")[[1]]

  df3_filter <- df3() %>% filter(Jahr %in% year_vector)

  p2<-ggplot(data = df3()) +
    {if(input$type=="Linie")
    {geom_line(aes_string(x = as.Date(df3()$date), y = input$variable3, group = df3()$Jahr), alpha = 0.8, color = "darkgrey", linewidth = 0.1)}
      else if(input$type=="Punkte")
      {geom_point(aes_string(color=df3()$Jahr))}
      else if(input$type=="Balken")
      {geom_col(aes_string(fill=df3()$Jahr), alpha=0.4, position = 'identity')}
    }+
    geom_line(data = df3_filter,
              aes_string(x = df3_filter$date, y = input$variable3,
                         color = df3_filter$Jahr))+
    scale_x_date(date_breaks = "1 week", date_labels = "%d-%b")+
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5),
      plot.background = element_rect(fill='transparent', color=NA),
      legend.background = element_rect(fill='transparent', color=NA)
      )+
    labs(x= "" ,color = "Jahre")

  ggplotly(if (input$smooth_trend) {
    print(p2 + geom_smooth(aes_string(x = as.Date(df3()$date), y = input$variable3), se = FALSE))
  }
  else{
    p2
  },
  tooltip = c("text","y"), height = as.numeric(input$dimension[2])*0.9)
})

# render description
output$description3 <- renderUI({
  HTML(
    str_glue(
      "
      Diese Grafik zeigt die
      <strong>{input$variable3}</strong>
      des Standortes
      <strong>{input$selectLocation}</strong>
      für die Jahre
      <strong>{input$year3}</strong>
      .
      "
    )
  )
})
