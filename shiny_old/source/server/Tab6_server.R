# query data
df6 <- reactive({
  con %>%
    tbl("Tagesdaten") %>%
    filter(Name_Station == input$selectLocation) %>%
    {if(input$current_year6 == FALSE) filter(., DATUM <= as.Date("2024-12-31")) else .} %>%
    mutate(Jahr = year(DATUM)) %>%
    collect() %>%
    group_by(Jahr) %>%
    summarise(Tage = case_when(
      input$ycol_over == "Lufttemperatur" ~ sum(
        if (input$auswahl) {Lufttemperatur >= input$sliderInput1} else
        {Lufttemperatur <= input$sliderInput1},
        na.rm = TRUE
      ),
      input$ycol_over == "Schneehoehe" ~ sum(
        if (input$auswahl) {Schneehoehe >= input$sliderInput1} else
        {Schneehoehe <= input$sliderInput1},
        na.rm = TRUE
      ),
      input$ycol_over == "Sonnenscheindauer" ~ sum(
        if (input$auswahl) {Sonnenscheindauer >= input$sliderInput1} else
        {Sonnenscheindauer <= input$sliderInput1},
        na.rm = TRUE
      ),
      input$ycol_over == "Niederschlagshoehe" ~ sum(
        if (input$auswahl) {Niederschlagshoehe >= input$sliderInput1} else
        {Niederschlagshoehe <= input$sliderInput1},
        na.rm = TRUE
      )
    ))
})

# render description
output$description6 <- renderUI({
  HTML(
    paste0(
      " Diese Grafik zeigt die Anzahl der Tage pro Jahr mit einer <strong>",
      input$ycol_over,
      "</strong> <u>",
      ifelse(input$auswahl == TRUE, "über", "unter"),
      "</u> <strong>",
      input$sliderInput1,
      case_when(
        input$ycol_over %in% c(
          "Lufttemperatur",
          "Tagesmaximaltemperatur",
          "Tagesminimaltemperatur") ~ " °C",
        input$ycol_over == "Schneehoehe" ~ " cm",
        input$ycol_over == "Sonnenscheindauer" ~ " h",
        input$ycol_over == "Niederschlagshoehe" ~ " l/m²"
      ),
      "</strong> ",
      "für den Standort ",
      "<strong>", input$selectLocation, "</strong>",
      " an."
    )
    )
  })

output$over_sliderinput <- renderUI({
  if (input$ycol_over == "Lufttemperatur") {
    sliderInput(
      "sliderInput1",
      paste0("Schwellenwert der ", input$ycol_over, " festlegen:"),
      min = -30,
      max = 40,
      value = 10
    )
  } else if (input$ycol_over == "Tagesmaximaltemperatur") {
    sliderInput(
      "sliderInput1",
      paste0("Schwellenwert der ", input$ycol_over, " festlegen:"),
      min = -30,
      max = 40,
      value = 10
    )
  } else if (input$ycol_over == "Tagesminimaltemperatur") {
    sliderInput(
      "sliderInput1",
      paste0("Schwellenwert der ", input$ycol_over, " festlegen:"),
      min = -30,
      max = 40,
      value = 10
    )
  } else if (input$ycol_over == "Schneehoehe") {
    sliderInput(
      "sliderInput1",
      paste0("Schwellenwert der ", input$ycol_over, " festlegen:"),
      min = 0,
      max = 100,
      value = 10
    )
  } else if (input$ycol_over == "Sonnenscheindauer") {
    sliderInput(
      "sliderInput1",
      paste0("Schwellenwert der ", input$ycol_over, " festlegen:"),
      min = 0,
      max = 24,
      value = 5
    )
  } else if (input$ycol_over == "Niederschlagshoehe") {
    sliderInput(
      "sliderInput1",
      paste0(
        "Schwellenwert der ",
        input$ycol_over,
        " festlegen:"
      ),
      min = 0,
      max = 50,
      value = 5
    )
  }
})

output$plot_over_1 <- renderPlotly({
  ggplotly(
    ggplot(
      data = df6(),
      aes_string(x = "Jahr", y = "Tage", fill = "Tage")
    )+
      geom_bar(stat = "identity", size = 10) +
      scale_fill_gradient(
        low = case_when(input$auswahl == TRUE & input$ycol_over %in% c(
          "Lufttemperatur") ~ "blue",
          input$auswahl == TRUE & input$ycol_over == "Schneehoehe" ~ "green",
          input$auswahl == TRUE & input$ycol_over == "Sonnenscheindauer" ~ "black",
          input$auswahl == TRUE & input$ycol_over == "Niederschlagshoehe" ~ "brown",
          input$auswahl == FALSE & input$ycol_over %in% c(
            "Lufttemperatur") ~ "red",
          input$auswahl == FALSE & input$ycol_over == "Schneehoehe" ~ "blue",
          input$auswahl == FALSE & input$ycol_over == "Sonnenscheindauer" ~ "yellow",
          input$auswahl == FALSE & input$ycol_over == "Niederschlagshoehe" ~ "blue"
        ),
        high = case_when(input$auswahl == TRUE & input$ycol_over %in% c(
          "Lufttemperatur") ~ "red",
          input$auswahl == TRUE & input$ycol_over == "Schneehoehe" ~ "blue",
          input$auswahl == TRUE & input$ycol_over == "Sonnenscheindauer" ~ "yellow",
          input$auswahl == TRUE & input$ycol_over == "Niederschlagshoehe" ~ "blue",
          input$auswahl == FALSE & input$ycol_over %in% c(
            "Lufttemperatur") ~ "blue",
          input$auswahl == FALSE & input$ycol_over == "Schneehoehe" ~ "green",
          input$auswahl == FALSE & input$ycol_over == "Sonnenscheindauer" ~ "black",
          input$auswahl == FALSE & input$ycol_over == "Niederschlagshoehe" ~ "brown"
        )
      )+
      theme(
        legend.position = "none",
        axis.title.y=element_blank(),
        plot.background = element_rect(fill='transparent', color=NA)
      ),
    tooltip = c("x","y")
  )
})
