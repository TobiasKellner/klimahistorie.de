testthat::test_that("navigation and native sidebar controls work in the browser", {
  app <- shinytest2::AppDriver$new(
    app_dir = normalizePath(testthat::test_path("..", "..")),
    name = "interactions",
    width = 1400,
    height = 900,
    load_timeout = 30000,
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  visible <- function(id) {
    app$get_js(sprintf(
      "(() => { let el = document.getElementById('%s'); if (el?.tagName === 'SELECT') el = el.closest('.shiny-input-container').querySelector('.selectize-control') || el; return !!el && el.getClientRects().length > 0 && !el.hidden; })()",
      id
    ))
  }
  toggle <- function(id, close) {
    selector <- sprintf("button.collapse-toggle[aria-controls='%s']", id)
    app$run_js(sprintf(
      "document.querySelector(\"%s\").scrollIntoView({block: 'center'})",
      selector
    ))
    app$click(selector = selector)
    app$wait_for_js("document.querySelector('.tooltip.show') === null")
    app$wait_for_js(sprintf(
      "document.querySelector(\"%s\").getAttribute('aria-expanded') === '%s'",
      selector,
      if (close) "false" else "true"
    ))
    testthat::expect_identical(visible(id), !close)
    testthat::expect_true(app$get_js(sprintf(
      "document.getElementById('%s').getBoundingClientRect().width %s",
      id,
      if (close) "=== 0" else "> 0"
    )))
  }
  select_tab <- function(id) {
    app$click(selector = sprintf("#sidebar_tabs a[data-value='%s']", id))
    app$wait_for_js(sprintf(
      "document.querySelector('.tab-pane.active[data-value=\"%s\"]') !== null",
      id
    ))
    app$wait_for_idle()
  }

  testthat::expect_true(visible("trends-station"))
  testthat::expect_true(app$get_js(
    "Array.from(document.querySelectorAll('button.collapse-toggle')).every(button => !button.hasAttribute('title') && button.getAttribute('aria-label') === 'Seitenleiste ein/ausklappen' && bootstrap.Tooltip.getInstance(button)?._config.placement === 'right')"
  ))
  app$run_js(
    "bootstrap.Tooltip.getInstance(document.querySelector(\"button.collapse-toggle[aria-controls='navigation_sidebar']\")).show()"
  )
  app$wait_for_js(
    "document.querySelector('.tooltip.show[data-popper-placement=\"right\"] .tooltip-inner')?.textContent === 'Seitenleiste ein/ausklappen'"
  )
  toggle("navigation_sidebar", TRUE)
  toggle("navigation_sidebar", FALSE)
  ids <- c(
    "trends",
    "daily_values",
    "year_comparison",
    "daily_history",
    "records",
    "thresholds",
    "stations",
    "about"
  )
  for (id in ids) {
    select_tab(id)
    testthat::expect_equal(
      app$get_js(
        "document.querySelectorAll('#sidebar_tabs .nav-link.active').length"
      ),
      1
    )
    if (id %in% head(ids, 6)) {
      testthat::expect_true(visible(paste0(id, "-station")))
      toggle(paste0(id, "-filters"), TRUE)
      toggle(paste0(id, "-filters"), FALSE)
    }
  }

  select_tab("trends")
  app$set_inputs(`trends-variable` = "Schneehoehe")
  toggle("trends-filters", TRUE)
  select_tab("daily_values")
  select_tab("trends")
  toggle("trends-filters", FALSE)
  testthat::expect_identical(
    app$get_value(input = "trends-variable"),
    "Schneehoehe"
  )

  app$set_window_size(width = 390, height = 844)
  toggle("navigation_sidebar", TRUE)
  toggle("navigation_sidebar", FALSE)
  select_tab("records")
  toggle("records-filters", TRUE)
  toggle("records-filters", FALSE)
  testthat::expect_true(visible("records-record_type"))
})
