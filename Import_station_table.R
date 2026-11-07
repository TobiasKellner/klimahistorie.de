# Intro -------------------------------------------------------------------

# Author: TK
# Dieses Skript importiert alle Rohzeilen des rdwd-Stationsindexes.

# Setup -------------------------------------------------------------------

library(dplyr)
library(tibble)
library(rdwd)
library(DBI)
library(dbx)

source("etl/db_connection.R")

options(rdwdlocdir = paste0(getwd(), "/DWDdata"))


# Import ------------------------------------------------------------------

df <- rdwd:::metaIndex |> as_tibble()


# Transformation ----------------------------------------------------------

df <- df |>
  rename(STATIONS_ID = Stations_id)

station_key <- c(
  "STATIONS_ID",
  "res",
  "var",
  "per",
  "von_datum",
  "bis_datum",
  "Abgabe"
)
if (anyNA(df[station_key])) {
  stop("Der Stationsschlüssel enthält fehlende Werte.")
}
if (anyDuplicated(df[station_key])) {
  stop("Der Stationsschlüssel ist im Rohindex nicht eindeutig.")
}


# Export ------------------------------------------------------------------

con <- db_connection()

tryCatch(
  dbWithTransaction(con, {
    dbxUpsert(
      conn = con,
      table = "Stationstabelle",
      records = df,
      where_cols = station_key,
      batch_size = 1000,
      skip_existing = FALSE
    )
  }),
  finally = dbDisconnect(con)
)
