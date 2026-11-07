app_dir <- normalizePath(testthat::test_path("..", ".."))
app_functions <- new.env(parent = globalenv())
for (file in sort(list.files(
  file.path(app_dir, "R"),
  "\\.R$",
  full.names = TRUE
))) {
  sys.source(file, envir = app_functions)
}
