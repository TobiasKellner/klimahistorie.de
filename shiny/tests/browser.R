local({
  app_dir <- if (dir.exists("shiny/R")) "shiny" else "."
  testthat::test_dir(
    file.path(app_dir, "tests", "browser"),
    stop_on_failure = TRUE
  )
})
