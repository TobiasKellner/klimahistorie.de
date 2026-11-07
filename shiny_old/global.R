# Packages ---------------------------------------------------------------

library(shiny)
library(bslib)
library(shinyjs)
library(shinycssloaders)
library(htmltools)
library(dplyr)
library(DBI)
library(lubridate)
library(purrr)
library(stringr)
library(ggplot2)
library(plotly)
library(leaflet)

source("authentication/db_connection.R")


# Database connection -----------------------------------------------------

config <- config::get(file = "authentication/config.yml")

con <- NULL
stations_liste <- character(0)

try(
  {
    con <- db_connection()

    onStop(function() {
      if (!is.null(con) && DBI::dbIsValid(con)) {
        dbDisconnect(con)
        print("DB-connection closed")
      }
    })

    stations_liste <- dbGetQuery(
      con,
      "SELECT DISTINCT \"Name_Station\" FROM \"Tagesdaten\""
    ) |>
      pull(Name_Station)
  },
  silent = TRUE
)

if (length(stations_liste) == 0) {
  stations_liste <- "Keine Station verfügbar"
}


# create named month vector
month_list <- setNames(
  c(0, 1:12),
  c(
    "Gesamtes Jahr",
    "Januar",
    "Februar",
    "März",
    "April",
    "Mai",
    "Juni",
    "Juli",
    "August",
    "September",
    "Oktober",
    "November",
    "Dezember"
  )
)

# query station list now handled with fallback above
