port <- Sys.getenv("SHINY_PORT", "3838")
healthy <- tryCatch(
  local({
    connection <- url(sprintf("http://127.0.0.1:%s/", port), open = "rb")
    on.exit(close(connection))
    html <- paste(readLines(connection, warn = FALSE), collapse = "\n")
    grepl("Klimahistorie.de", html, fixed = TRUE)
  }),
  error = function(e) FALSE
)
quit(status = if (healthy) 0L else 1L)
