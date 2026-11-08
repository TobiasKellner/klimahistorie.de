app_navigation <- function() {
  data.frame(
    id = c(
      "trends",
      "daily_values",
      "year_comparison",
      "daily_history",
      "records",
      "thresholds",
      "overview",
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
      "Klima auf einen Blick",
      "Stationsübersicht",
      "Über Klimashistorie.de"
    ),
    icon = c(
      "chart-line",
      "calendar-day",
      "chart-bar",
      "history",
      "trophy",
      "arrows-alt-v",
      "eye",
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
