testthat::test_that("module inputs and native collapse controls are namespaced", {
  ids <- head(app_functions$app_navigation()$id, 6)
  for (id in ids) {
    ui <- app_functions[[paste0("mod_", id, "_ui")]](id)
    html <- htmltools::renderTags(ui)$html
    testthat::expect_match(html, paste0('id="', id, '-station"'), fixed = TRUE)
    testthat::expect_match(
      html,
      paste0('aria-controls="', id, '-filters"'),
      fixed = TRUE
    )
    testthat::expect_match(html, 'data-open-desktop="open"', fixed = TRUE)
  }
})

testthat::test_that("the composed app has unique IDs and no legacy scripts", {
  html <- htmltools::renderTags(app_functions$app_ui(app_dir))$html
  matches <- regmatches(
    html,
    gregexpr('(?<=\\s)id="[^"]+"', html, perl = TRUE)
  )[[1]]
  testthat::expect_identical(anyDuplicated(matches), 0L)
  testthat::expect_match(html, 'id="navigation_sidebar"', fixed = TRUE)
  testthat::expect_false(grepl(
    "lte.pushmenu|brand-text|toggle_filters_tab",
    html
  ))
  testthat::expect_match(html, "app-logo", fixed = TRUE)
})

testthat::test_that("the entry point works from root and app directory", {
  from_root <- withr::with_dir(
    dirname(app_dir),
    source("shiny/app.R", local = new.env())$value
  )
  from_app <- withr::with_dir(app_dir, source("app.R", local = new.env())$value)
  testthat::expect_s3_class(from_root, "shiny.appobj")
  testthat::expect_s3_class(from_app, "shiny.appobj")
})
