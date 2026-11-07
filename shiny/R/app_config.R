app_navigation <- function() {
  data.frame(
    id = c(
      "trends",
      "daily_values",
      "year_comparison",
      "daily_history",
      "records",
      "thresholds",
      "stations",
      "about"
    ),
    label = c(
      "Durchschnitte & Trends",
      "Tageswerte",
      "Jahresvergleich",
      "Tageshistorie",
      "Klimarekorde",
      "Tage über & unter",
      "Stationsübersicht",
      "Über die Web-App"
    ),
    icon = c(
      "chart-line",
      "calendar-day",
      "chart-bar",
      "history",
      "trophy",
      "arrows-alt-v",
      "map-marked-alt",
      "info-circle"
    ),
    stringsAsFactors = FALSE
  )
}

app_station_choices <- function() "Wird noch geladen"

app_variable_choices <- function() {
  c("Lufttemperatur", "Schneehoehe", "Sonnenscheindauer", "Niederschlagshoehe")
}
