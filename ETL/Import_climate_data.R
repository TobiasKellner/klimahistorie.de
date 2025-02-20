# Intro -------------------------------------------------------------------

# Author: TK
# This script downloads all available data


# Setup -------------------------------------------------------------------

library(dplyr)
library(purrr)
library(stringr)
library(lubridate)
library(rdwd)
library(DBI)
library(dbx)

source("~/klimahistorie.de/shiny/authentication/db_connection.R")

options(rdwdlocdir = paste0(getwd(), "/DWDdata"))

# source database connection function

Liste <-
  c(
    "Berlin-Tempelhof",
    "Erfurt-Weimar",
    "Jena (Sternwarte)",
    "Frankfurt/Main",
    "Stuttgart-Echterdingen",
    "Hannover",
    "Hamburg-Neuwiedenthal",
    "Koeln-Bonn",
    "Potsdam",
    "Duesseldorf",
    "Dresden-Hosterwitz",
    "Muenchen-Flughafen",
    "Eschwege",
    "Norderney",
    "List auf Sylt",
    "Schmuecke",
    "Brocken",
    "Fichtelberg",
    "Feldberg/Schwarzwald",
    "Zugspitze",
    "Saarbruecken-Ensheim",
    "Leipzig/Halle",
    # "Mainz-Lerchenberg (ZDF)",
    "Bremen",
    "Kiel-Holtenau",
    "Rostock-Warnemuende",
    "Magdeburg",
    "Schwerin",
    "Grosser Arber",
    "Nuernberg",
    "Friedrichshafen",
    "Cottbus",
    "Kleiner Feldberg/Taunus",
    "Muenster/Osnabrueck",
    "Waren (Mueritz)",
    "Eisenach",
    "Gera-Leumnitz",
    "Goettingen",
    "Wuerzburg",
    "Aachen-Orsbach",
    "Wittenberg",
    "Muehlhausen/Thueringen-Goermar",
    "Freiburg",
    "Ingolstadt (Flugplatz)",
    "Regensburg",
    "Chemnitz",
    "Trier-Petrisberg",
    "Freiburg/Elbe",
    "Lenzen/Elbe",
    "Luebeck-Blankensee",
    "Fehmarn",
    "Bremerhaven",
    "Braunschweig",
    "Augsburg",
    "Helgoland"
  ) %>%
  sort()


# Import ------------------------------------------------------------------

dataset <- map_df(Liste, ~{

  # download historical climate data
  df_historical <- readDWD(dataDWD(
    selectDWD(
      name = .x,
      res = "daily",
      var = "kl",
      per = "historical"
    ) |>
     str_replace("20221231", "20231231"),
    read = FALSE
  ), varnames = TRUE)

  # download recent climate data
  df_recent<-
    readDWD(dataDWD(
      selectDWD(
        name = .x,
        res = "daily",
        var = "kl",
        per = "recent"
      ),
      read = FALSE,
      force = T
    ), varnames = TRUE)

  # bind historical and recent data frames
  bind_rows(df_historical, df_recent) %>%
    mutate(
      Name_Station = .x,
      Jahr = MESS_DATUM %>% year(),
      Monat = MESS_DATUM %>% month(label = T, abbr = F)
    )

}) %>%
  distinct(STATIONS_ID, MESS_DATUM,.keep_all = T)


# Transformation ----------------------------------------------------------

# rename columns
dataset <- dataset %>%
  transmute(
    STATIONS_ID,
    DATUM = MESS_DATUM %>% as.Date(),
    QN_3,
    Windspitze = FX.Windspitze,
    Windgeschwindigkeit = FM.Windgeschwindigkeit,
    QN_4,
    Niederschlagshoehe = RSK.Niederschlagshoehe,
    Niederschlagsform = RSKF.Niederschlagsform,
    Sonnenscheindauer = SDK.Sonnenscheindauer,
    Schneehoehe = SHK_TAG.Schneehoehe,
    Bedeckungsgrad = NM.Bedeckungsgrad,
    Dampfdruck = VPM.Dampfdruck,
    Luftdruck = PM.Luftdruck,
    Lufttemperatur = TMK.Lufttemperatur,
    Relative_Feuchte = UPM.Relative_Feuchte,
    Lufttemperatur_Max = TXK.Lufttemperatur_Max,
    Lufttemperatur_Min = TNK.Lufttemperatur_Min,
    Lufttemperatur_5cm_min = TGK.Lufttemperatur_5cm_min,
    eor,
    Name_Station
  )


# Export ------------------------------------------------------------------

con <- db_connection()

# dbCreateTable(conn = con, name = "Tagesdaten", dataset)
#
# dbSendQuery(con, 'ALTER TABLE "Tagesdaten" ADD PRIMARY KEY ("STATIONS_ID", "DATUM") ')

dbxUpsert(
  conn = con,
  table = "Tagesdaten",
  records = dataset,
  where_cols = c("STATIONS_ID", "DATUM"),
  batch_size = 1000,
  skip_existing = FALSE
  )

dbDisconnect(con)

# delete all downloaded zip-files after inserting all information into database
do.call(file.remove, list(list.files(paste0(getwd(),"/DWDdata"), full.names = TRUE)))
