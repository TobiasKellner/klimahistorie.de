# Intro -------------------------------------------------------------------

# Author: TK
# This script downloads all available data


# Setup -------------------------------------------------------------------

library(dplyr)
library(tibble)
library(purrr)
library(stringr)
library(lubridate)
library(rdwd)
library(DBI)
library(dbx)

source("~/klimahistorie.de/shiny/authentication/db_connection.R")

options(rdwdlocdir = paste0(getwd(), "/DWDdata"))


# Import ------------------------------------------------------------------

df <- rdwd:::metaIndex |> as_tibble()


# Transformation ----------------------------------------------------------

df <- df %>%
  filter(
    res == "daily",
    var == "kl",
    bis_datum >= today() - years(2)
    ) %>%
  distinct(Stations_id, .keep_all = TRUE) %>%
  select(Stations_id,
         Stationshoehe,
         geoBreite,
         geoLaenge,
         Stationsname,
         Bundesland) %>%
  rename(STATIONS_ID = Stations_id)


# Export ------------------------------------------------------------------

con <- db_connection()

# dbCreateTable(conn = con, name = "Stationstabelle", df)

# dbSendQuery(con, 'ALTER TABLE "Stationstabelle" ADD PRIMARY KEY ("STATIONS_ID") ')

dbxUpsert(
  conn = con,
  table = "Stationstabelle",
  records = df,
  where_cols = c("STATIONS_ID"),
  batch_size = 1000,
  skip_existing = FALSE
)

dbDisconnect(con)
