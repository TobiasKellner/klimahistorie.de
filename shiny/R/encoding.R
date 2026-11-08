app_require_utf8 <- function() {
  if (isTRUE(l10n_info()[["UTF-8"]])) {
    return(invisible(NULL))
  }
  # LC_CTYPE is sufficient; keep numeric, date and sorting conventions unchanged.
  for (locale in c("C.UTF-8", "en_US.UTF-8", "UTF-8")) {
    suppressWarnings(Sys.setlocale("LC_CTYPE", locale))
    if (isTRUE(l10n_info()[["UTF-8"]])) {
      return(invisible(NULL))
    }
  }
  stop(
    "The app requires a UTF-8 locale for chart labels. Configure a UTF-8 R session locale and restart the app.",
    call. = FALSE
  )
}
