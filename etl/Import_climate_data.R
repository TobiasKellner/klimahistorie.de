library(DBI)
library(RPostgres)
library(dbx)
library(rdwd)
library(lubridate)

source("etl/db_connection.R")
source("etl/daily_data.R")

daily_import_result <- import_daily_data()
