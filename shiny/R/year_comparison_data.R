year_comparison_years <- function(text) {
  if (
    !is.character(text) ||
      length(text) != 1L ||
      is.na(text) ||
      !grepl("^[0-9]{4}(\\s*,\\s*[0-9]{4})*$", trimws(text))
  ) {
    stop(
      "Bitte vierstellige Jahre durch Kommas getrennt eingeben.",
      call. = FALSE
    )
  }
  years <- unique(as.integer(trimws(strsplit(trimws(text), ",")[[1]])))
  if (any(years < 1L)) {
    stop("Ungültiges Vergleichsjahr.", call. = FALSE)
  }
  years
}

year_comparison_data <- function(
  db_pool,
  station,
  variable,
  month = 0,
  query = database_query
) {
  if (
    length(station) != 1L ||
      is.na(station) ||
      !grepl("^[1-9][0-9]*$", as.character(station)) ||
      as.numeric(station) > .Machine$integer.max
  ) {
    stop("Ungültige Stations-ID.", call. = FALSE)
  }
  variables <- trends_variables()
  if (
    length(variable) != 1L || is.na(variable) || !variable %in% variables$name
  ) {
    stop("Ungültige Klimavariable.", call. = FALSE)
  }
  if (
    length(month) != 1L ||
      is.na(month) ||
      !as.character(month) %in% as.character(0:12)
  ) {
    stop("Ungültiger Monat.", call. = FALSE)
  }
  empty <- data.frame(
    date = as.Date(character()),
    year = integer(),
    calendar_date = as.Date(character()),
    value = double()
  )
  if (is.null(db_pool)) {
    return(empty)
  }
  column <- variables$column[match(variable, variables$name)]
  sql <- paste(
    'SELECT "MESS_DATUM" AS date,',
    sprintf('NULLIF("%s", -999) AS value', column),
    'FROM public."Tagesdaten" WHERE "STATIONS_ID" = $1',
    if (as.integer(month) != 0L) 'AND substring("MESS_DATUM", 5, 2) = $2::text',
    'ORDER BY "MESS_DATUM"'
  )
  params <- list(as.integer(station))
  if (as.integer(month) != 0L) {
    params <- c(params, list(sprintf("%02d", as.integer(month))))
  }
  data <- trends_query(db_pool, sql, params = params, query = query)
  if (!nrow(data)) {
    return(empty)
  }
  dates <- as.Date(data$date, format = "%Y%m%d")
  valid <- !is.na(dates) &
    !is.na(data$date) &
    format(dates, "%Y%m%d") == data$date
  data <- data[valid, , drop = FALSE]
  dates <- dates[valid]
  values <- data$value
  values[!is.finite(values) | values == -999] <- NA_real_
  result <- data.frame(
    date = dates,
    year = as.integer(format(dates, "%Y")),
    # A leap-year anchor preserves calendar alignment, including February 29.
    calendar_date = as.Date(paste0("2000-", format(dates, "%m-%d"))),
    value = values
  )
  result[order(result$date), , drop = FALSE]
}

year_comparison_mean <- function(values) {
  values <- values[is.finite(values$value), , drop = FALSE]
  if (!nrow(values)) {
    return(data.frame(calendar_date = as.Date(character()), value = double()))
  }
  stats::aggregate(value ~ calendar_date, data = values, FUN = mean)
}

year_comparison_plot <- function(
  values,
  years,
  type,
  variable,
  average = FALSE
) {
  if (!type %in% c("Linie", "Punkte", "Balken")) {
    stop("Ungültiger Diagrammtyp.", call. = FALSE)
  }
  selected <- values[values$year %in% years, , drop = FALSE]
  selected$year <- factor(selected$year, levels = years)
  unit <- trends_variables()$unit[match(variable, trends_variables()$name)]
  values$tooltip <- paste0(
    "Datum: ",
    format(values$date, "%d.%m.%Y"),
    "<br>Wert: ",
    values$value,
    " ",
    unit
  )
  selected$tooltip <- paste0(
    "Datum: ",
    format(selected$date, "%d.%m.%Y"),
    "<br>Wert: ",
    selected$value,
    " ",
    unit
  )
  graph <- ggplot2::ggplot(
    values,
    ggplot2::aes(calendar_date, value, group = year, text = tooltip)
  )
  graph <- switch(
    type,
    Linie = graph +
      ggplot2::geom_line(color = "darkgrey", linewidth = 0.2, na.rm = TRUE) +
      ggplot2::geom_line(
        data = selected,
        ggplot2::aes(color = year),
        na.rm = TRUE
      ),
    Punkte = graph +
      ggplot2::geom_point(color = "darkgrey", alpha = 0.3, na.rm = TRUE) +
      ggplot2::geom_point(
        data = selected,
        ggplot2::aes(color = year),
        na.rm = TRUE
      ),
    Balken = graph +
      ggplot2::geom_col(
        fill = "darkgrey",
        alpha = 0.15,
        position = "identity",
        na.rm = TRUE
      ) +
      ggplot2::geom_col(
        data = selected,
        ggplot2::aes(fill = year),
        alpha = 0.7,
        position = "identity",
        na.rm = TRUE
      )
  )
  if (isTRUE(average)) {
    graph <- graph +
      ggplot2::geom_line(
        data = year_comparison_mean(values),
        ggplot2::aes(
          calendar_date,
          value,
          linetype = "Durchschnitt aller Jahre"
        ),
        inherit.aes = FALSE,
        linewidth = 0.8
      )
  }
  graph +
    ggplot2::scale_x_date(
      date_breaks = "1 week",
      date_labels = "%d.%m.",
      expand = ggplot2::expansion(mult = 0.01)
    ) +
    ggplot2::labs(
      x = NULL,
      y = paste(variable, "in", unit),
      color = "Jahre",
      fill = "Jahre",
      linetype = NULL
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5)
    )
}
