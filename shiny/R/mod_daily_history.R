mod_daily_history_ui <- function(id) {
  ns <- shiny::NS(id)

  filter_card_ui(
    full_screen = TRUE,
    title = station_map_header("Tageshistorie", ns),
    sidebar_id = ns("filters"),
    controls = shiny::tagList(
      shiny::selectInput(
        ns("station"),
        "Standort",
        choices = app_station_choices()
      ),
      shiny::dateInput(
        ns("date"),
        "Tag auswählen",
        value = Sys.Date(),
        language = "de",
        format = "dd.mm.yyyy",
        weekstart = 1
      ),
      shiny::helpText(
        "Tag und Monat werden über alle verfügbaren Jahre verglichen."
      ),
      shiny::selectInput(
        ns("variable"),
        "Variable",
        choices = app_variable_choices()
      ),
      bslib::input_switch(
        ns("average"),
        "Durchschnitt anzeigen",
        value = FALSE
      ),
      bslib::input_switch(
        ns("descending"),
        "Nach Messwert absteigend sortieren",
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

mod_daily_history_server <- function(
  id,
  db_pool = NULL,
  stations = trends_station_choices,
  location = function(pool, station) stations_map_data(pool, station = station),
  show = shiny::showModal,
  daily = daily_history_data
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
    data <- shiny::reactive({
      shiny::validate(shiny::need(
        length(choices()) > 0L,
        "Keine Stationen verfügbar oder keine Datenbank konfiguriert."
      ))
      shiny::req(input$station %in% choices(), input$date, input$variable)
      tryCatch(
        daily(db_pool, input$station, input$date, input$variable),
        error = function(e) {
          shiny::validate(shiny::need(
            FALSE,
            "Die Tageshistorie konnte nicht geladen werden."
          ))
        }
      )
    })
    station_label <- shiny::reactive({
      shiny::req(input$station %in% choices())
      names(choices())[match(input$station, choices())]
    })
    output$description <- shiny::renderUI({
      shiny::req(input$date, input$variable)
      shiny::p(
        "Historische ",
        shiny::strong(input$variable),
        " am Standort ",
        shiny::strong(station_label()),
        " für den ",
        shiny::strong(format(input$date, "%d.%m.")),
        " in allen verfügbaren Jahren. Die Durchschnittslinie zeigt das Mittel der gültigen Tageswerte."
      )
    })
    output$plot <- plotly::renderPlotly({
      values <- data()
      shiny::validate(shiny::need(
        any(is.finite(values$value) & values$value != -999),
        "Für diesen Kalendertag liegen keine gültigen Messwerte vor."
      ))
      plotly::ggplotly(
        daily_history_plot(
          values,
          input$variable,
          station_label(),
          isTRUE(input$average),
          isTRUE(input$descending)
        ),
        tooltip = "text"
      )
    })
    shiny::reactive(list(station = input$station, date = input$date))
  })
}
