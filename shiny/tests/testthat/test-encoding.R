testthat::test_that("Plotly hover labels survive startup from a non-UTF-8 locale", {
  withr::with_locale(c(LC_CTYPE = "C"), {
    numeric_locale <- Sys.getlocale("LC_NUMERIC")
    app_functions$app_require_utf8()
    testthat::expect_true(l10n_info()[["UTF-8"]])
    testthat::expect_identical(Sys.getlocale("LC_NUMERIC"), numeric_locale)

    tooltip <- "M\u00fcnchen: Tage \u00fcber 20 \u00b0C"
    data <- data.frame(x = 1, y = 2, tooltip = tooltip)
    chart <- ggplot2::ggplot(data, ggplot2::aes(x, y, text = tooltip)) +
      ggplot2::geom_point()
    widget <- plotly::ggplotly(chart, tooltip = "text")
    payload <- plotly::plotly_json(widget, jsonedit = FALSE)
    decoded <- jsonlite::fromJSON(as.character(payload), simplifyVector = FALSE)

    testthat::expect_identical(decoded$data[[1]]$text[[1]], tooltip)
    testthat::expect_false(grepl("<U+", payload, fixed = TRUE))
  })
})
