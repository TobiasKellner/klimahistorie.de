daily_column_types <- function() {
  c(
    STATIONS_ID = "integer",
    MESS_DATUM = "character",
    QN_3 = "integer",
    FX = "numeric",
    FM = "numeric",
    QN_4 = "integer",
    RSK = "numeric",
    RSKF = "integer",
    SDK = "numeric",
    SHK_TAG = "integer",
    NM = "numeric",
    VPM = "numeric",
    PM = "numeric",
    TMK = "numeric",
    UPM = "numeric",
    TXK = "numeric",
    TNK = "numeric",
    TGK = "numeric",
    eor = "character"
  )
}

validate_daily_data <- function(data) {
  if (!identical(names(data), names(daily_column_types()))) {
    stop(
      "Unerwartete DWD-Tagesdatenspalten. Schema vor dem Import prüfen.",
      call. = FALSE
    )
  }
  key <- c("STATIONS_ID", "MESS_DATUM")
  if (anyNA(data[key]) || any(!grepl("^[0-9]{8}$", data$MESS_DATUM))) {
    stop("Ungültiger Tagesdatenschlüssel.", call. = FALSE)
  }
  dates <- as.Date(data$MESS_DATUM, format = "%Y%m%d")
  if (anyNA(dates) || any(format(dates, "%Y%m%d") != data$MESS_DATUM)) {
    stop("Ungültiges MESS_DATUM.", call. = FALSE)
  }
  if (anyDuplicated(data[key])) {
    stop(
      "Doppelte Tagesdatenschlüssel innerhalb derselben Herkunft.",
      call. = FALSE
    )
  }
  invisible(data)
}

read_daily_text <- function(connection) {
  data <- utils::read.table(
    connection,
    header = TRUE,
    sep = ";",
    strip.white = TRUE,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    comment.char = "",
    quote = "",
    na.strings = character(),
    colClasses = daily_column_types()
  )
  names(data) <- trimws(names(data))
  validate_daily_data(data)
  data
}

read_daily_archive <- function(path) {
  entries <- utils::unzip(path, list = TRUE)$Name
  member <- entries[grepl("(^|/)produkt_.*\\.txt$", entries)]
  if (length(member) != 1L) {
    stop(
      "Das DWD-Archiv muss genau eine Produktdatei enthalten.",
      call. = FALSE
    )
  }
  connection <- unz(path, member)
  # read.table may close an initially unopened zip connection itself.
  on.exit(try(close(connection), silent = TRUE))
  read_daily_text(connection)
}

merge_daily_data <- function(historical, recent) {
  validate_daily_data(historical)
  validate_daily_data(recent)
  # Recent is first so it wins for the same station/day.
  data <- rbind(recent, historical)
  data <- data[
    !duplicated(data[c("STATIONS_ID", "MESS_DATUM")]),
    ,
    drop = FALSE
  ]
  rownames(data) <- NULL
  validate_daily_data(data)
  data
}

daily_archive_urls <- function(urls) {
  # selectDWD returns the base directory URL when its selection is empty.
  urls <- urls[!is.na(urls) & nzchar(urls) & !endsWith(urls, "/")]
  if (any(!grepl("\\.zip$", urls, ignore.case = TRUE))) {
    stop(
      "Die DWD-Auswahl enthält eine unerwartete Archivadresse.",
      call. = FALSE
    )
  }
  urls
}

download_daily_period <- function(station_id, period, cache_dir) {
  urls <- rdwd::selectDWD(
    id = station_id,
    res = "daily",
    var = "kl",
    per = period,
    failempty = FALSE,
    quiet = TRUE
  )
  urls <- daily_archive_urls(urls)
  if (!length(urls)) {
    return(as.data.frame(lapply(daily_column_types(), function(type) {
      switch(
        type,
        integer = integer(),
        numeric = numeric(),
        character = character()
      )
    })))
  }
  datasets <- lapply(urls, function(url) {
    url <- sub("^ftp://", "https://", url)
    path <- file.path(cache_dir, basename(url))
    if (period == "recent" || !file.exists(path)) {
      utils::download.file(url, path, mode = "wb", quiet = TRUE)
    }
    data <- read_daily_archive(path)
    if (any(data$STATIONS_ID != station_id)) {
      stop(
        "Die Produktdatei enthält eine unerwartete Stations-ID.",
        call. = FALSE
      )
    }
    data
  })
  data <- do.call(rbind, datasets)
  validate_daily_data(data)
  data
}

limit_daily_station_ids <- function(station_ids, n_stations = NULL) {
  if (
    !is.null(n_stations) &&
      (!is.numeric(n_stations) ||
        length(n_stations) != 1L ||
        !is.finite(n_stations) ||
        n_stations < 1 ||
        n_stations != trunc(n_stations))
  ) {
    stop(
      "n_stations muss NULL oder eine positive ganze Zahl sein.",
      call. = FALSE
    )
  }
  station_ids <- unique(station_ids)
  if (is.null(n_stations)) station_ids else head(station_ids, n_stations)
}

import_daily_data <- function(
  cache_dir = "DWDdata",
  station_ids = NULL,
  progress = TRUE,
  n_stations = NULL
) {
  if (!is.logical(progress) || length(progress) != 1L || is.na(progress)) {
    stop("progress muss TRUE oder FALSE sein.", call. = FALSE)
  }
  # Validate the limit before connecting; explicit IDs retain their supplied order.
  station_ids <- limit_daily_station_ids(station_ids, n_stations)
  con <- db_connection()
  on.exit(DBI::dbDisconnect(con))
  if (!DBI::dbExistsTable(con, "Tagesdaten")) {
    stop("Zuerst Migration 004 für Tagesdaten ausführen.", call. = FALSE)
  }
  if (
    !setequal(DBI::dbListFields(con, "Tagesdaten"), names(daily_column_types()))
  ) {
    stop(
      "Die Tagesdaten-Tabelle entspricht nicht dem Rohschema.",
      call. = FALSE
    )
  }
  if (is.null(station_ids)) {
    # Preserve the existing scope of current daily KL stations.
    cutoff <- as.character(lubridate::today() - lubridate::years(2))
    station_ids <- DBI::dbGetQuery(
      con,
      paste(
        'SELECT DISTINCT "STATIONS_ID" FROM public."Stationstabelle"',
        'WHERE res = \'daily\' AND var = \'kl\' AND hasfile',
        'AND bis_datum >= $1::date ORDER BY "STATIONS_ID"'
      ),
      params = list(cutoff)
    )$STATIONS_ID
  }
  if (!length(station_ids)) {
    stop("Keine Stationen für den Import ausgewählt.", call. = FALSE)
  }
  if (
    anyNA(station_ids) ||
      any(station_ids <= 0 | station_ids != trunc(station_ids))
  ) {
    stop("Ungültige Stations-IDs.", call. = FALSE)
  }
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  station_ids <- limit_daily_station_ids(station_ids, n_stations)
  total <- length(station_ids)
  started <- proc.time()[["elapsed"]]
  results <- lapply(seq_along(station_ids), function(index) {
    station_id <- station_ids[[index]]
    report <- function(phase) {
      if (progress) {
        message(sprintf(
          "[%d/%d] Station %d: %s",
          index,
          total,
          station_id,
          phase
        ))
      }
    }
    report("historische Daten laden")
    historical <- download_daily_period(station_id, "historical", cache_dir)
    report("aktuelle Daten laden")
    recent <- download_daily_period(station_id, "recent", cache_dir)
    data <- merge_daily_data(historical, recent)
    if (!nrow(data)) {
      stop("Keine Tagesdaten für die ausgewählte Station.", call. = FALSE)
    }
    report(sprintf("%d Zeilen per Upsert speichern", nrow(data)))
    DBI::dbWithTransaction(con, {
      dbx::dbxUpsert(
        conn = con,
        table = "Tagesdaten",
        records = data,
        where_cols = c("STATIONS_ID", "MESS_DATUM"),
        batch_size = 1000,
        skip_existing = FALSE
      )
    })
    if (progress) {
      message(sprintf(
        "[%d/%d] Station %d abgeschlossen — %.1f%%; Laufzeit %.1f min",
        index,
        total,
        station_id,
        100 * index / total,
        (proc.time()[["elapsed"]] - started) / 60
      ))
    }
    Sys.sleep(0.1)
    data.frame(STATIONS_ID = station_id, imported_rows = nrow(data))
  })
  do.call(rbind, results)
}
