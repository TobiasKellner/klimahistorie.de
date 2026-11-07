mod_thresholds_ui <- function(id) {
  ns <- shiny::NS(id)

  filter_card_ui(
    full_screen = TRUE,
    title = station_map_header("Tage über & unter", ns),
    sidebar_id = ns("filters"),
    controls = shiny::tagList(
      shiny::selectInput(
        ns("station"),
        "Standort",
        choices = app_station_choices()
      ),
      shiny::selectInput(
        ns("variable"),
        "Variable",
        choices = app_variable_choices()
      ),
      shiny::radioButtons(
        ns("direction"),
        "Tage zählen",
        choices = c(
          "Über (einschließlich)" = "over",
          "Unter (einschließlich)" = "under"
        ),
        selected = "over"
      ),
      shiny::uiOutput(ns("threshold_input")),
      bslib::input_switch(
        ns("include_current"),
        "Laufendes Jahr einbeziehen",
        value = FALSE
      )
    ),
    content = bslib::card_body(
      class = "p-0",
      shiny::uiOutput(ns("description")),
      bslib::as_fill_carrier(shinycssloaders::withSpinner(
        plotly::plotlyOutput(ns("plot"), height = "100%")
      ))
    )
  )
}

mod_thresholds_server <- function(
  id,
  db_pool = NULL,
  stations = trends_station_choices,
  location = function(pool, station) stations_map_data(pool, station = station),
  show = shiny::showModal,
  annual = thresholds_annual_data
) {
  shiny::moduleServer(id, function(input, output, session) {
    choices <- station_selection_server(session, db_pool, stations)
    station_map_modal_server(
      input,
      output,
      session,
      db_pool,
      choices,
      location,
      show
    )
    output$threshold_input <- shiny::renderUI({
      shiny::req(input$variable)
      settings <- thresholds_settings(input$variable)
      shiny::sliderInput(
        session$ns("threshold"),
        paste("Schwellenwert in", settings$unit),
        min = settings$min,
        max = settings$max,
        value = settings$default,
        step = 1
      )
    })
    data <- shiny::reactive({
      shiny::validate(shiny::need(
        length(choices()) > 0L,
        "Keine Stationen verfügbar oder keine Datenbank konfiguriert."
      ))
      shiny::req(
        input$station %in% choices(),
        input$variable,
        !is.null(input$threshold),
        input$direction
      )
      tryCatch(
        annual(
          db_pool,
          input$station,
          input$variable,
          input$threshold,
          direction = input$direction,
          include_current = isTRUE(input$include_current)
        ),
        error = function(e) {
          shiny::validate(shiny::need(
            FALSE,
            "Die Klimadaten konnten nicht geladen werden."
          ))
        }
      )
    })
    station_label <- shiny::reactive({
      names(choices())[match(input$station, choices())]
    })
    output$description <- shiny::renderUI({
      shiny::req(
        input$station %in% choices(),
        input$variable,
        !is.null(input$threshold),
        input$direction
      )
      settings <- thresholds_settings(input$variable)
      shiny::p(
        "Anzahl der Tage pro Jahr mit ",
        shiny::strong(settings$label),
        if (input$direction == "over") {
          " größer oder gleich "
        } else {
          " kleiner oder gleich "
        },
        shiny::strong(paste(input$threshold, settings$unit)),
        " am Standort ",
        shiny::strong(station_label()),
        "."
      )
    })
    output$plot <- plotly::renderPlotly({
      values <- data()
      shiny::validate(shiny::need(
        nrow(values) > 0L,
        "Für diese Auswahl liegen keine gültigen Messwerte vor."
      ))
      fill_colors <- trends_fill_colors(input$variable)
      values$tooltip <- paste0(
        htmltools::htmlEscape(station_label()),
        "<br>Jahr: ",
        values$year,
        "<br>Tage auf/",
        if (input$direction == "over") "über" else "unter",
        " der Schwelle: ",
        values$n_threshold,
        "<br>Gültige Tageswerte: ",
        values$n_days
      )
      plotly::ggplotly(
        ggplot2::ggplot(
          values,
          ggplot2::aes(x = year, y = n_threshold, text = tooltip)
        ) +
          ggplot2::geom_col(ggplot2::aes(fill = n_threshold)) +
          ggplot2::scale_fill_gradient(
            low = fill_colors[["low"]],
            high = fill_colors[["high"]],
            guide = "none"
          ) +
          ggplot2::scale_x_continuous(
            expand = ggplot2::expansion(mult = 0.01, add = 0.1)
          ) +
          ggplot2::labs(x = "Jahr", y = "Anzahl der Tage") +
          ggplot2::theme_minimal(),
        tooltip = "text"
      )
    })
    shiny::reactive(list(
      station = input$station,
      variable = input$variable,
      threshold = input$threshold,
      direction = input$direction,
      include_current = input$include_current
    ))
  })
}
