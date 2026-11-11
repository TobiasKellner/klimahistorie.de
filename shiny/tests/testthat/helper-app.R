app_dir <- normalizePath(testthat::test_path("..", ".."))
app_functions <- new.env(parent = globalenv())
for (file in sort(list.files(
  file.path(app_dir, "R"),
  "\\.R$",
  full.names = TRUE
))) {
  eval(
    parse(
      text = readLines(file, encoding = "UTF-8", warn = FALSE),
      encoding = "UTF-8",
      keep.source = FALSE
    ),
    envir = app_functions
  )
}
