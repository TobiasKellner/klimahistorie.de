local({
  app_dir <- if (dir.exists('R') && file.exists('app.R')) {
    normalizePath('.')
  } else {
    normalizePath('shiny', mustWork = TRUE)
  }
  local_config <- file.path(app_dir, '.Renviron')
  if (file.exists(local_config)) {
    readRenviron(local_config)
  }
  app_env <- new.env(parent = globalenv())
  for (file in sort(list.files(
    file.path(app_dir, 'R'),
    '\\.R$',
    full.names = TRUE
  ))) {
    # Preserve Unicode even when the process uses a non-UTF-8 locale.
    eval(
      parse(
        text = readLines(file, encoding = "UTF-8", warn = FALSE),
        encoding = "UTF-8",
        keep.source = FALSE
      ),
      envir = app_env
    )
  }
  app_env$app_require_utf8()
  database <- app_env$database_lifecycle()
  shiny::shinyApp(
    ui = app_env$app_ui(app_dir),
    server = function(input, output, session) {
      app_env$app_server(input, output, session, db_pool = database$get())
    },
    onStart = database$start
  )
})
