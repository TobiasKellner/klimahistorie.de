testthat::test_that("navigation has stable unique identifiers and complete metadata", {
  nav <- app_functions$app_navigation()
  testthat::expect_equal(nrow(nav), 9L)
  testthat::expect_identical(nav$id[[1]], "trends")
  testthat::expect_false(anyDuplicated(nav$id) > 0)
  testthat::expect_true(all(nzchar(nav$label) & nzchar(nav$icon)))
  testthat::expect_match(paste(nav$id, collapse = ""), "^[a-z_]+$")
  testthat::expect_identical(
    app_functions$app_station_choices(),
    "Wird noch geladen"
  )
  testthat::expect_length(app_functions$app_variable_choices(), 4L)
})
