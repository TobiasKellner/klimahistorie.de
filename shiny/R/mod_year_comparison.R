mod_year_comparison_ui <- function(id) {
  ns <- shiny::NS(id)

  filter_card_ui(
    full_screen = TRUE,
    title = station_map_header("Jahresvergleich", ns),
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
      shiny::textInput(ns("years"), "Jahre", value = "2024,2023"),
      shiny::helpText(
        "Vergleichsjahre durch Kommas trennen. Grau: alle verfügbaren Jahre."
      ),
      shiny::selectInput(
        ns("type"),
        "Darstellung",
        choices = c("Linie", "Punkte", "Balken")
      ),
      bslib::input_switch(
        ns("average"),
        "Durchschnittsverlauf anzeigen",
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

mod_year_comparison_server <- function(
  id,
  db_pool = NULL,
  stations = trends_station_choices,
  daily = year_comparison_data,
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
          selected = station_default_selection(choices)
        )
      },
      once = TRUE
    )
    station_map_modal_server(
      input,
      output,
      session,
      db_pool,
      station_choices,
      location,
      show
    )
    years <- shiny::reactive({
      shiny::req(input$years)
      tryCatch(year_comparison_years(input$years), error = function(e) {
        shiny::validate(shiny::need(FALSE, conditionMessage(e)))
      })
    })
    data <- shiny::reactive({
      shiny::validate(shiny::need(is.null(station_error()), station_error()))
      shiny::validate(shiny::need(
        length(station_choices()) > 0L,
        "Keine Stationen verfügbar oder keine Datenbank konfiguriert."
      ))
      shiny::req(
        input$station %in% station_choices(),
        input$variable,
        input$month
      )
      tryCatch(
        daily(db_pool, input$station, input$variable, input$month),
        error = function(e) {
          shiny::validate(shiny::need(
            FALSE,
            "Die Vergleichsdaten konnten nicht geladen werden."
          ))
        }
      )
    })
    output$description <- shiny::renderUI({
      shiny::req(input$station %in% station_choices(), input$variable)
      selected <- years()
      label <- names(station_choices())[match(input$station, station_choices())]
      shiny::p(
        "Vergleich der ",
        shiny::strong(input$variable),
        " am Standort ",
        shiny::strong(label),
        " für ",
        shiny::strong(paste(selected, collapse = ", ")),
        ". Der Durchschnitt umfasst alle verfügbaren Jahre je Kalendertag."
      )
    })
    output$plot <- plotly::renderPlotly({
      selected <- years()
      values <- data()
      shiny::req(input$type)
      shiny::validate(shiny::need(
        any(is.finite(values$value)),
        "Für diese Auswahl liegen keine gültigen Messwerte vor."
      ))
      shiny::validate(shiny::need(
        any(values$year %in% selected & is.finite(values$value)),
        "Für die gewählten Vergleichsjahre liegen keine gültigen Messwerte vor."
      ))
      plotly::ggplotly(
        year_comparison_plot(
          values,
          selected,
          input$type,
          input$variable,
          isTRUE(input$average)
        ),
        tooltip = "text"
      )
    })
    shiny::reactive(list(station = input$station, years = input$years))
  })
}
