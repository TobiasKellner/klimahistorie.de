port <- suppressWarnings(as.numeric(Sys.getenv("SHINY_PORT", "3838")))
if (
  is.na(port) ||
    !is.finite(port) ||
    port != trunc(port) ||
    port < 1024 ||
    port > 65535
) {
  stop("SHINY_PORT must be an integer between 1024 and 65535.")
}
options(
  shiny.host = "0.0.0.0",
  shiny.port = as.integer(port),
  sass.cache = FALSE
)
shiny::runApp(
  "/app",
  host = "0.0.0.0",
  port = as.integer(port),
  launch.browser = FALSE
)
