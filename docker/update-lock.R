# Run from the repository root after deliberately updating the project lockfile.
local({
  lock <- jsonlite::read_json("renv.lock")
  required <- c(
    "shiny",
    "bslib",
    "htmltools",
    "renv",
    "DBI",
    "RPostgres",
    "pool",
    "ggplot2",
    "plotly",
    "lubridate",
    "leaflet",
    "shinycssloaders"
  )
  standard <- c(
    "R",
    rownames(utils::installed.packages(priority = c("base", "recommended")))
  )
  repeat {
    stopifnot(all(required %in% names(lock$Packages)))
    dependencies <- unique(unlist(lapply(
      lock$Packages[required],
      function(record) {
        fields <- as.character(unlist(
          record[c("Depends", "Imports", "LinkingTo", "Requirements")],
          use.names = FALSE
        ))
        trimws(sub("\\s*\\(.*$", "", unlist(strsplit(fields, ","))))
      }
    )))
    missing <- setdiff(dependencies, c(names(lock$Packages), standard))
    if (length(missing)) {
      stop(
        "Dependencies missing from project lockfile: ",
        paste(missing, collapse = ", ")
      )
    }
    expanded <- sort(unique(c(
      required,
      intersect(dependencies, names(lock$Packages))
    )))
    if (setequal(required, expanded)) {
      break
    }
    required <- expanded
  }
  lock$Packages <- lock$Packages[required]
  jsonlite::write_json(
    lock,
    "docker/renv.lock",
    auto_unbox = TRUE,
    pretty = TRUE
  )
})
