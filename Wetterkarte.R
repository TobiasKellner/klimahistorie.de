# Aus der Projektwurzel mit source("Wetterkarte.R") starten.
local({
  library(DBI)
  library(pool)
  library(RPostgres)
  library(leaflet)
  library(htmltools)

  datum <- Sys.Date() - 30
  variable <- "TMK" # TMK, TNK, TXK, RSK, SDK oder SHK_TAG

  erstelle_karte <- function(datum, variable) {
    kennzahlen <- data.frame(
      spalte = c("TMK", "TNK", "TXK", "RSK", "SDK", "SHK_TAG"),
      titel = c(
        "Tagesmitteltemperatur",
        "Minimaltemperatur",
        "Maximaltemperatur",
        "Niederschlagshöhe",
        "Sonnenscheindauer",
        "Schneehöhe"
      ),
      einheit = c("°C", "°C", "°C", "mm", "h", "cm")
    )
    stopifnot(
      inherits(datum, "Date"),
      length(datum) == 1L,
      !is.na(datum),
      length(variable) == 1L,
      variable %in% kennzahlen$spalte
    )
    kennzahl <- kennzahlen[match(variable, kennzahlen$spalte), ]

    konfiguration <- "shiny/.Renviron"
    if (file.exists(konfiguration)) {
      readRenviron(konfiguration)
    }
    datenbank <- new.env(parent = globalenv())
    sys.source("shiny/R/db_pool.R", envir = datenbank)
    verbindung <- datenbank$database_pool_create()
    if (is.null(verbindung)) {
      stop(
        "Keine Datenbank konfiguriert. Bitte die PostgreSQL-Umgebungsvariablen wie für die Shiny-App setzen.",
        call. = FALSE
      )
    }
    on.exit(poolClose(verbindung), add = TRUE)

    # Die Spalte stammt aus der festen Auswahlliste; das Datum wird gebunden.
    sql <- paste(
      'SELECT s."STATIONS_ID", s."Stationsname", s."geoBreite", s."geoLaenge",',
      sprintf('       NULLIF(t."%s", -999) AS wert', variable),
      'FROM public."Tagesdaten" t',
      'JOIN public."AktuelleTemperaturstationen" s USING ("STATIONS_ID")',
      'WHERE t."MESS_DATUM" = $1::text',
      sprintf('AND NULLIF(t."%s", -999) IS NOT NULL', variable),
      'AND s."geoBreite" BETWEEN -90 AND 90',
      'AND s."geoLaenge" BETWEEN -180 AND 180'
    )
    werte <- tryCatch(
      dbGetQuery(verbindung, sql, params = list(format(datum, "%Y%m%d"))),
      error = function(e) {
        stop("Die Wetterdaten konnten nicht geladen werden.", call. = FALSE)
      }
    )
    werte <- werte[is.finite(werte$wert), ]
    if (!nrow(werte)) {
      stop(
        "Für dieses Datum liegen keine gültigen Messwerte mit Stationskoordinaten vor. Bitte ein anderes Datum wählen.",
        call. = FALSE
      )
    }

    farben <- colorNumeric("RdYlBu", domain = werte$wert, reverse = TRUE)
    beschriftung <- paste0(
      htmlEscape(werte$Stationsname),
      "<br>",
      format(datum, "%d.%m.%Y"),
      "<br>",
      kennzahl$titel,
      ": ",
      format(werte$wert, decimal.mark = ",", trim = TRUE),
      " ",
      kennzahl$einheit,
      "<br>Stations-ID: ",
      werte$STATIONS_ID
    )
    leaflet(werte) |>
      addTiles() |>
      setView(lng = 10.4, lat = 51.1, zoom = 6) |>
      addCircleMarkers(
        lng = ~geoLaenge,
        lat = ~geoBreite,
        radius = 6,
        stroke = FALSE,
        fillOpacity = 0.85,
        fillColor = ~ farben(wert),
        popup = beschriftung,
        label = lapply(beschriftung, HTML)
      ) |>
      addLegend(
        position = "bottomright",
        pal = farben,
        values = ~wert,
        title = paste0(kennzahl$titel, " (", kennzahl$einheit, ")")
      ) |>
      addControl(
        html = paste0(
          "<strong>",
          kennzahl$titel,
          " am ",
          format(datum, "%d.%m.%Y"),
          "</strong><br>",
          nrow(werte),
          " Stationen mit gültigen Messwerten"
        ),
        position = "topright"
      )
  }

  print(erstelle_karte(datum, variable))
})
