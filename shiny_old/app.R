`%||%` <- function(x, y) if (is.null(x)) y else x

app_dir <- dirname(normalizePath(
  sys.frame(1)$ofile %||% "shiny_old/app.R",
  mustWork = FALSE
))
source(file.path(app_dir, "global.R"), local = TRUE)
source(file.path(app_dir, "ui.R"), local = TRUE)

server <- source(file.path(app_dir, "server.R"), local = TRUE)$value

shinyApp(ui, server)
