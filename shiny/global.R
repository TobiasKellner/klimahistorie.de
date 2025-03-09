# Packages ---------------------------------------------------------------

library(shiny)
library(shinyjs)
library(shinycssloaders)
library(bs4Dash)
library(htmltools)
library(dplyr)
library(lubridate)
library(purrr)
library(stringr)
library(ggplot2)
library(plotly)
library(leaflet)

source("authentication/db_connection.R")


# Database connection -----------------------------------------------------

config <- config::get(file = "authentication/config.yml")

con <- db_connection()

onStop(function() {
  dbDisconnect(con)
  print("DB-connection closed")
  })



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

# query station list
Stationsliste <- dbGetQuery(con, "SELECT DISTINCT \"Name_Station\" FROM \"Tagesdaten\"") %>%
  pull(Name_Station)
