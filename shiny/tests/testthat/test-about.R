testthat::test_that("about view contains project history, methodology and safe links", {
  html <- htmltools::renderTags(app_functions$view_about_ui())$html
  for (text in c(
    "Über Klimashistorie.de",
    "Tobias Kellner",
    "Prima-Klima-App.de",
    "Digitalpreis 2021",
    "Datenquelle und Methodik",
    "PostgreSQL",
    "Presse und Projektgeschichte"
  )) {
    testthat::expect_match(html, text, fixed = TRUE)
  }
  for (url in c(
    "https://github.com/TobiasKellner/klimahistorie.de",
    "https://opendata.dwd.de/",
    "https://www.uni-erfurt.de/",
    "https://www.leg-thueringen.de/"
  )) {
    testthat::expect_match(html, url, fixed = TRUE)
  }
  testthat::expect_match(html, 'rel="noopener noreferrer"', fixed = TRUE)
  testthat::expect_false(grepl("Platzhaltertext|Apache Airflow", html))
  nav <- app_functions$app_navigation()
  testthat::expect_identical(
    nav$label[nav$id == "about"],
    "Über Klimashistorie.de"
  )
})
