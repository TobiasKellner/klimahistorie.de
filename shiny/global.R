# Packages ---------------------------------------------------------------

library(shiny)
library(shinyjs)
library(bs4Dash)
library(htmltools)
library(dplyr)
library(lubridate)
library(purrr)
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




month_list <- c("Gesamtes Jahr","Januar","Februar","März","April","Mai","Juni","Juli","August","September","Oktober","November","Dezember")

