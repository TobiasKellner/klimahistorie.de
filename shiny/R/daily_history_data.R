daily_history_data <- function(
  db_pool,
  station,
  date,
  variable,
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
  if (!inherits(date, "Date") || length(date) != 1L || is.na(date)) {
    stop("Ungültiges Datum.", call. = FALSE)
  }
  variables <- trends_variables()
  if (
    length(variable) != 1L || is.na(variable) || !variable %in% variables$name
  ) {
    stop("Ungültige Klimavariable.", call. = FALSE)
  }
  empty <- data.frame(
    date = as.Date(character()),
    year = integer(),
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
    'AND substring("MESS_DATUM", 5, 4) = $2::text ORDER BY "MESS_DATUM"'
  )
  data <- trends_query(
    db_pool,
    sql,
    params = list(as.integer(station), format(date, "%m%d")),
    query = query
  )
  if (!nrow(data)) {
    return(empty)
  }
  dates <- as.Date(data$date, format = "%Y%m%d")
  valid <- !is.na(dates) &
    !is.na(data$date) &
    format(dates, "%Y%m%d") == data$date &
    format(dates, "%m%d") == format(date, "%m%d") &
    is.finite(data$value) &
    data$value != -999
  result <- data.frame(
    date = dates[valid],
    year = as.integer(format(dates[valid], "%Y")),
    value = data$value[valid]
  )
  result[order(result$year), , drop = FALSE]
}

daily_history_order <- function(values, descending = FALSE) {
  values <- values[
    is.finite(values$value) & values$value != -999,
    ,
    drop = FALSE
  ]
  index <- if (isTRUE(descending)) {
    order(-values$value, values$year)
  } else {
    order(values$year)
  }
  values <- values[index, , drop = FALSE]
  values$year <- factor(values$year, levels = values$year)
  values
}

daily_history_plot <- function(
  values,
  variable,
  station,
  average = FALSE,
  descending = FALSE
) {
  values <- daily_history_order(values, descending)
  unit <- trends_variables()$unit[match(variable, trends_variables()$name)]
  colors <- trends_fill_colors(variable)
  values$tooltip <- paste0(
    htmltools::htmlEscape(station),
    "<br>Datum: ",
    format(values$date, "%d.%m.%Y"),
    "<br>Wert: ",
    values$value,
    " ",
    unit
  )
  graph <- ggplot2::ggplot(values, ggplot2::aes(year, value, text = tooltip)) +
    ggplot2::geom_col(ggplot2::aes(fill = value)) +
    ggplot2::scale_fill_gradient(
      low = colors[["low"]],
      high = colors[["high"]],
      guide = "none"
    ) +
    ggplot2::scale_x_discrete(expand = ggplot2::expansion(add = 0.6)) +
    ggplot2::labs(x = "Jahr", y = paste(variable, "in", unit)) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5)
    )
  if (isTRUE(average) && nrow(values)) {
    graph <- graph +
      ggplot2::geom_hline(
        yintercept = mean(values$value),
        color = "blue",
        linewidth = 0.6
      )
  }
  graph
}
