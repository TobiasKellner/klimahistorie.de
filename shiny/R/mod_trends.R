trends_fill_colors <- function(variable) {
  switch(
    variable,
    Lufttemperatur = c(low = "blue", high = "red"),
    Schneehoehe = c(low = "green", high = "blue"),
    Sonnenscheindauer = c(low = "black", high = "yellow"),
    Niederschlagshoehe = c(low = "brown", high = "blue"),
    stop("Ungültige Klimavariable.", call. = FALSE)
  )
}

mod_trends_ui <- function(id) {
  ns <- shiny::NS(id)

  filter_card_ui(
    full_screen = TRUE,
    title = shiny::tags$div(
      class = "d-flex justify-content-between align-items-center w-100",
      shiny::tags$span("Durchschnitt & Trend"),
      shiny::actionButton(
        ns("show_map"),
        "Karte",
        icon = shiny::icon("map"),
        class = "btn-sm btn-success"
      )
    ),
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
      shiny::selectInput(
        ns("month"),
        "Jahr / Monat",
        choices = trends_month_choices()
      ),
      bslib::input_switch(
        ns("include_current"),
        "Laufendes Jahr einbeziehen",
        value = FALSE
      ),
      bslib::input_switch(
        ns("regline"),
        "Linearen Trend anzeigen",
        value = FALSE
      )
    ),
    content = bslib::card_body(
      class = "p-0",
      shiny::uiOutput(ns("description")),
      bslib::as_fill_carrier(
        shinycssloaders::withSpinner(
          plotly::plotlyOutput(ns("plot"), height = "100%")
        )
      )
    )
  )
}

mod_trends_server <- function(
  id,
  db_pool = NULL,
  stations = trends_station_choices,
  annual = trends_annual_data,
  location = function(pool, station) stations_map_data(pool, station = station),
  show = shiny::showModal
) {
  shiny::moduleServer(id, function(input, output, session) {
    station_choices <- shiny::reactiveVal(character())
    station_error <- shiny::reactiveVal(NULL)
    shiny::observeEvent(
      TRUE,
      {
        choices <- tryCatch(stations(db_pool), error = function(e) {
          station_error("Die Stationsliste konnte nicht geladen werden.")
          character()
        })
        station_choices(choices)
        shiny::updateSelectInput(
          session,
          "station",
          choices = choices,
          selected = if (length(choices)) unname(choices[[1L]]) else character()
        )
      },
      once = TRUE
    )
    data <- shiny::reactive({
      shiny::validate(shiny::need(is.null(station_error()), station_error()))
      shiny::validate(shiny::need(
        length(station_choices()) > 0L,
        "Keine Stationen mit aktuellem DWD-Lufttemperaturangebot verfügbar oder keine Datenbank konfiguriert."
      ))
      shiny::req(
        input$station %in% station_choices(),
        input$variable,
        input$month
      )
      tryCatch(
        annual(
          db_pool,
          input$station,
          input$variable,
          input$month,
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
      labels <- names(station_choices())
      labels[match(input$station, station_choices())]
    })
    map_location <- shiny::reactiveVal(NULL)
    shiny::observeEvent(input$show_map, {
      shiny::req(input$station %in% station_choices())
      selected <- tryCatch(
        location(db_pool, input$station),
        error = function(e) NULL
      )
      map_location(selected)
      content <- if (is.null(selected) || nrow(selected) != 1L) {
        shiny::p("Die Stationskarte ist für diesen Standort nicht verfügbar.")
      } else {
        leaflet::leafletOutput(session$ns("station_map"), height = "450px")
      }
      show(shiny::modalDialog(
        title = paste("Wetterstation:", station_label()),
        content,
        size = "l",
        easyClose = TRUE,
        footer = shiny::modalButton("Schließen", icon = shiny::icon("xmark"))
      ))
    })
    output$station_map <- leaflet::renderLeaflet({
      selected <- map_location()
      shiny::req(!is.null(selected), nrow(selected) == 1L)
      labels <- stations_map_labels(selected)
      leaflet::leaflet(selected) |>
        leaflet::addTiles() |>
        leaflet::addAwesomeMarkers(
          lng = ~geoLaenge,
          lat = ~geoBreite,
          icon = leaflet::awesomeIcons(
            icon = "circle",
            library = "fa",
            markerColor = "blue",
            iconColor = "#FFFFFF"
          ),
          label = labels,
          popup = labels
        ) |>
        leaflet::setView(
          selected$geoLaenge[[1]],
          selected$geoBreite[[1]],
          zoom = 10
        )
    })
    output$description <- shiny::renderUI({
      shiny::req(
        input$station %in% station_choices(),
        input$variable,
        input$month
      )
      month <- names(trends_month_choices())[match(
        input$month,
        trends_month_choices()
      )]
      shiny::p(
        "Durchschnittliche ",
        shiny::strong(input$variable),
        " am Standort ",
        shiny::strong(station_label()),
        " — ",
        month,
        "."
      )
    })
    output$plot <- plotly::renderPlotly({
      values <- data()
      shiny::validate(shiny::need(
        nrow(values) > 0L,
        "Für diese Auswahl liegen keine gültigen Messwerte vor."
      ))
      variable <- trends_variables()
      unit <- variable$unit[match(input$variable, variable$name)]
      fill_colors <- trends_fill_colors(input$variable)
      values$tooltip <- paste0(
        htmltools::htmlEscape(station_label()),
        "<br>Jahr: ",
        values$year,
        "<br>Mittelwert: ",
        values$value,
        " ",
        unit,
        "<br>Gültige Tageswerte: ",
        values$n_days
      )
      graph <- ggplot2::ggplot(
        values,
        ggplot2::aes(x = year, y = value, text = tooltip)
      ) +
        ggplot2::geom_col(ggplot2::aes(fill = value)) +
        ggplot2::scale_x_continuous(
          expand = ggplot2::expansion(mult = 0.01, add = 0.1)
        ) +
        ggplot2::scale_fill_gradient(
          low = fill_colors[["low"]],
          high = fill_colors[["high"]],
          guide = "none"
        ) +
        ggplot2::labs(x = "Jahr", y = paste(input$variable, "in", unit)) +
        ggplot2::theme_minimal()
      if (isTRUE(input$regline)) {
        trend <- trends_regression(values)
        if (nrow(trend)) {
          graph <- graph +
            ggplot2::geom_line(
              data = trend,
              ggplot2::aes(x = year, y = value),
              inherit.aes = FALSE
            )
        }
      }
      plotly::ggplotly(graph, tooltip = "text")
    })
    shiny::reactive(list(
      station = input$station,
      variable = input$variable,
      month = input$month
    ))
  })
}
