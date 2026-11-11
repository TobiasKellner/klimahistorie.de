mod_overview_ui <- function(id) {
  ns <- shiny::NS(id)
  filter_card_ui(
    station_map_header("Klima auf einen Blick", ns),
    ns("filters"),
    controls = shiny::tagList(
      shiny::selectInput(ns("station"), "Station", app_station_choices()),
      shiny::selectInput(ns("year"), "Kalenderjahr", choices = character()),
      shiny::p(
        class = "text-muted small",
        "Jahreskennzahlen werden nur bei vollständigen Tageswerten angezeigt."
      )
    ),
    content = shiny::tags$div(
      class = "climate-overview",
      shiny::uiOutput(ns("headline")),
      shiny::uiOutput(ns("values")),
      bslib::accordion(
        bslib::accordion_panel(
          "Datenqualität",
          shiny::uiOutput(ns("quality")),
          icon = shiny::icon("clipboard-check")
        ),
        id = ns("quality_details"),
        open = FALSE
      ),
      bslib::accordion(
        bslib::accordion_panel(
          "Was bedeuten die Kennzahlen?",
          shiny::tags$dl(
            shiny::tags$dt("Jahresmitteltemperatur"),
            shiny::tags$dd("Mittelwert aller Tagesmitteltemperaturen (TMK)."),
            shiny::tags$dt("Frosttage"),
            shiny::tags$dd(
              "Tage mit einer Minimaltemperatur unter 0 °C (TNK)."
            ),
            shiny::tags$dt("Heiße Tage"),
            shiny::tags$dd(
              "Tage mit einer Maximaltemperatur von mindestens 30 °C (TXK)."
            ),
            shiny::tags$dt("Niederschlagssumme"),
            shiny::tags$dd("Summe der täglichen Niederschlagshöhen (RSK)."),
            shiny::tags$dt("Maximal- und Minimaltemperatur"),
            shiny::tags$dd(
              "Höchste Tagesmaximaltemperatur (TXK) und niedrigste ",
              "Tagesminimaltemperatur (TNK) des Jahres, jeweils mit Datum. ",
              "Bei Gleichstand wird der erste Tag angezeigt."
            ),
            shiny::tags$dt("Sonnenscheindauer"),
            shiny::tags$dd(
              "Summe der täglichen Sonnenscheindauer in Stunden (SDK)."
            ),
            shiny::tags$dt("Tage mit Schneedecke"),
            shiny::tags$dd(
              "Tage mit gemessener Schneehöhe über 0 cm (SHK_TAG)."
            )
          ),
          shiny::p(
            "Die Referenz 1991–2020 wird je Kennzahl nur angezeigt, wenn alle ",
            "30 Kalenderjahre vollständig vorliegen. Stationsverlegungen und ",
            "Messänderungen können die Vergleichbarkeit beeinflussen. ",
            "Quelle: DWD; keine Homogenisierung der Stationsreihe."
          ),
          icon = shiny::icon("circle-info")
        ),
        open = FALSE
      )
    )
  )
}

overview_value_format <- function(value, unit) {
  if (length(value) != 1L || !is.finite(value)) {
    return("Nicht verfügbar")
  }
  digits <- if (unit == "Tage") 0L else 1L
  paste(
    format(
      round(value, digits),
      nsmall = digits,
      decimal.mark = ",",
      big.mark = ".",
      trim = TRUE
    ),
    unit
  )
}

mod_overview_server <- function(
  id,
  db_pool = NULL,
  stations = trends_station_choices,
  annual = overview_annual_data,
  location = function(pool, station) stations_map_data(pool, station = station),
  show = shiny::showModal
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
      shiny::req(input$station %in% unname(choices()))
      tryCatch(annual(db_pool, input$station), error = function(e) {
        shiny::validate(shiny::need(
          FALSE,
          "Die Klimadaten konnten nicht geladen werden. Bitte versuchen Sie es später erneut."
        ))
      })
    })
    shiny::observeEvent(data(), {
      years <- as.character(sort(data()$year, decreasing = TRUE))
      shiny::freezeReactiveValue(input, "year")
      shiny::updateSelectInput(
        session,
        "year",
        choices = years,
        selected = overview_default_year(data())
      )
    })
    selected <- shiny::reactive({
      shiny::validate(shiny::need(
        nrow(data()) > 0L,
        "Für diese Station sind noch keine Jahresdaten vorhanden."
      ))
      shiny::req(input$year %in% as.character(data()$year))
      data()[data()$year == as.integer(input$year), , drop = FALSE]
    })
    output$headline <- shiny::renderUI({
      row <- selected()
      label <- names(choices())[match(input$station, choices())]
      shiny::tags$div(
        class = "overview-hero",
        shiny::tags$div(
          shiny::tags$h2(label),
          shiny::p(
            "Acht Kennzahlen aus dem Kalenderjahr ",
            shiny::strong(row$year)
          )
        ),
        shiny::tags$span(class = "overview-year", row$year)
      )
    })
    output$values <- shiny::renderUI({
      row <- selected()
      metrics <- overview_metrics()
      boxes <- lapply(seq_len(nrow(metrics)), function(i) {
        key <- metrics$key[[i]]
        reference <- overview_reference(data(), key)
        value <- row[[key]][[1L]]
        extreme <- key %in% c("max_temperature", "min_temperature")
        count <- row[[paste0("n_", key)]][[1L]]
        comparison <- if (!is.finite(value)) {
          if (is.na(count) || count == 0L) {
            "Keine gültigen Tageswerte vorhanden"
          } else if (row$year >= as.integer(format(Sys.Date(), "%Y"))) {
            paste(count, "von", row$expected, "Tageswerten · laufendes Jahr")
          } else {
            paste(
              count,
              "von",
              row$expected,
              "gültigen Tageswerten · Jahresreihe unvollständig"
            )
          }
        } else if (extreme) {
          date <- row[[paste0(key, "_date")]][[1L]]
          if (is.finite(value) && !is.na(date)) {
            paste(
              "am",
              format(date, "%d.%m.%Y"),
              "· erster Tag bei Gleichstand"
            )
          } else {
            "Kein vollständiger Jahreswert verfügbar"
          }
        } else if (is.finite(value) && is.finite(reference)) {
          difference <- value - reference
          paste0(
            if (difference > 0) "+" else "",
            overview_value_format(difference, metrics$unit[[i]]),
            " gegenüber 1991–2020"
          )
        } else {
          "Kein vollständiger Jahres- oder Referenzwert verfügbar"
        }
        bslib::value_box(
          title = metrics$label[[i]],
          value = overview_value_format(value, metrics$unit[[i]]),
          shiny::p(class = "overview-comparison", comparison),
          if (is.finite(reference)) {
            shiny::p(
              class = "small",
              "Referenz: ",
              overview_value_format(reference, metrics$unit[[i]])
            )
          },
          showcase = shiny::icon(metrics$icon[[i]]),
          showcase_layout = "top right",
          theme = metrics$theme[[i]],
          fill = FALSE
        )
      })
      do.call(
        bslib::layout_columns,
        c(
          boxes,
          list(
            col_widths = bslib::breakpoints(sm = 6, xl = 3),
            fill = FALSE
          )
        )
      )
    })
    output$quality <- shiny::renderUI({
      row <- selected()
      metrics <- overview_metrics()
      running <- row$year >= as.integer(format(Sys.Date(), "%Y"))
      shiny::tagList(
        shiny::p(
          "Letzter vorhandener Messtag im ausgewählten Jahr: ",
          shiny::strong(format(row$last_date, "%d.%m.%Y")),
          if (running) {
            " · Laufendes Jahr: Noch keine abgeschlossenen Jahreskennzahlen."
          }
        ),
        lapply(seq_len(nrow(metrics)), function(i) {
          key <- metrics$key[[i]]
          n <- row[[paste0("n_", key)]][[1L]]
          complete <- !running && n == row$expected
          shiny::tags$div(
            class = "overview-quality-row",
            shiny::tags$div(
              class = "overview-quality-label",
              shiny::strong(metrics$label[[i]]),
              shiny::tags$span(
                class = if (complete) {
                  "badge text-bg-success"
                } else {
                  "badge text-bg-secondary"
                },
                if (complete) "Vollständig" else "Unvollständig"
              )
            ),
            shiny::tags$progress(
              value = n,
              max = row$expected,
              `aria-label` = paste(metrics$label[[i]], "gültige Tageswerte")
            ),
            shiny::tags$small(paste(
              n,
              "von",
              row$expected,
              "gültigen Tageswerten"
            ))
          )
        })
      )
    })
    shiny::reactive(list(station = input$station, year = input$year))
  })
}
