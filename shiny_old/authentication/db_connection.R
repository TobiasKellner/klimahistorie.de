library(DBI)
library(RPostgres)

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
