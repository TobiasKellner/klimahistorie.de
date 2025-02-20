library(DBI)
library(RPostgres)

config <- config::get(file = "~/klimahistorie.de/shiny/authentication/config.yml")

db_connection <- function() {

  dbConnect(
    RPostgres::Postgres(),
    dbname = config$db$name,
    host = config$db$host,
    port=config$db$port,
    user=config$db$user,
    password=config$db$password
    )
}
