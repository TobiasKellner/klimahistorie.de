contact_smtp_config <- function(getenv = Sys.getenv, read_secret = readLines) {
  if (!identical(tolower(getenv("CONTACT_SMTP_ENABLED", "false")), "true")) {
    return(NULL)
  }
  username <- trimws(getenv("CONTACT_SMTP_USERNAME", ""))
  recipient <- trimws(getenv("CONTACT_MAIL_TO", username))
  password_file <- getenv("CONTACT_SMTP_PASSWORD_FILE", "")
  port <- getenv("CONTACT_SMTP_PORT", "465")
  if (
    length(message_validation_errors("SMTP", username, "SMTP")) ||
      length(message_validation_errors("SMTP", recipient, "SMTP")) ||
      !nzchar(password_file) ||
      !port %in% c("465", "587")
  ) {
    stop("Unvollständige SMTP-Konfiguration.", call. = FALSE)
  }
  password <- read_secret(password_file, warn = FALSE)
  if (length(password) != 1L || !nzchar(password)) {
    stop("Ungültige SMTP-Passwortdatei.", call. = FALSE)
  }
  list(
    username = username,
    recipient = recipient,
    password = password,
    server = paste0(
      if (port == "465") "smtps://" else "smtp://",
      "smtp.ionos.de:",
      port
    )
  )
}

contact_mail_message <- function(subject, email, text, config) {
  encode <- function(x) {
    gsub("[\r\n]", "", jsonlite::base64_enc(charToRaw(enc2utf8(x))))
  }
  # Short RFC 2047 words preserve Unicode without exceeding header line limits.
  contact_subject <- trimws(subject)
  subject <- paste0("Kontaktformular: ", contact_subject)
  starts <- seq.int(1L, nchar(subject), by = 10L)
  encoded_subject <- vapply(
    starts,
    function(start) {
      paste0("=?UTF-8?B?", encode(substr(subject, start, start + 9L)), "?=")
    },
    character(1)
  )
  body <- encode(paste0(
    "Betreff: ",
    contact_subject,
    "\nE-Mail-Adresse: ",
    trimws(email),
    "\n\nNachricht:\n",
    trimws(text)
  ))
  starts <- seq.int(1L, nchar(body), by = 76L)
  body <- vapply(
    starts,
    function(start) {
      substr(body, start, start + 75L)
    },
    character(1)
  )
  paste(
    c(
      paste0("From: ", config$username),
      paste0("To: ", config$recipient),
      paste0("Reply-To: ", trimws(email)),
      paste0("Date: ", {
        date <- as.POSIXlt(Sys.time(), tz = "UTC")
        sprintf(
          "%02d %s %04d %02d:%02d:%02d +0000",
          date$mday,
          month.abb[date$mon + 1L],
          date$year + 1900L,
          date$hour,
          date$min,
          as.integer(date$sec)
        )
      }),
      paste0("Subject: ", paste(encoded_subject, collapse = "\r\n ")),
      "MIME-Version: 1.0",
      "Content-Type: text/plain; charset=UTF-8",
      "Content-Transfer-Encoding: base64",
      "",
      body,
      ""
    ),
    collapse = "\r\n"
  )
}

contact_send_mail <- function(
  subject,
  email,
  text,
  config = contact_smtp_config(),
  transport = curl::send_mail
) {
  if (is.null(config)) {
    stop("SMTP-Versand deaktiviert.", call. = FALSE)
  }
  errors <- message_validation_errors(subject, email, text)
  if (length(errors)) {
    stop("Ungültige Nachricht.", call. = FALSE)
  }
  transport(
    mail_from = config$username,
    mail_rcpt = config$recipient,
    message = contact_mail_message(subject, email, text, config),
    smtp_server = config$server,
    username = config$username,
    password = config$password,
    use_ssl = "force",
    ssl_verifypeer = TRUE,
    ssl_verifyhost = 2L,
    connecttimeout = 5,
    timeout = 10,
    verbose = FALSE
  )
  invisible(TRUE)
}
