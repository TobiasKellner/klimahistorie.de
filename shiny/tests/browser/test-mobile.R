testthat::test_that("phone layouts fit the viewport and preserve desktop dimensions", {
  app <- shinytest2::AppDriver$new(
    app_dir = normalizePath(testthat::test_path("..", "..")),
    name = "mobile",
    width = 390,
    height = 844,
    load_timeout = 30000,
    timeout = 10000
  )
  on.exit(app$stop(), add = TRUE)

  expanded <- function(id) {
    app$get_js(sprintf(
      "document.querySelector(\"button.collapse-toggle[aria-controls='%s']\").getAttribute('aria-expanded') === 'true'",
      id
    ))
  }
  set_sidebar <- function(id, open) {
    if (!identical(expanded(id), open)) {
      app$click(
        selector = sprintf("button.collapse-toggle[aria-controls='%s']", id)
      )
      app$wait_for_js(sprintf(
        "document.querySelector(\"button.collapse-toggle[aria-controls='%s']\").getAttribute('aria-expanded') === '%s'",
        id,
        if (open) "true" else "false"
      ))
    }
  }
  select_tab <- function(id) {
    set_sidebar("navigation_sidebar", TRUE)
    app$click(selector = sprintf("#sidebar_tabs a[data-value='%s']", id))
    app$wait_for_idle()
    set_sidebar("navigation_sidebar", FALSE)
  }
  fits_viewport <- function() {
    app$wait_for_js(
      "document.documentElement.scrollWidth <= window.innerWidth + 1"
    )
    testthat::expect_true(app$get_js(
      "document.documentElement.scrollWidth <= window.innerWidth + 1"
    ))
  }

  testthat::expect_false(expanded("navigation_sidebar"))
  testthat::expect_false(expanded("trends-filters"))
  for (width in c(320, 390, 575, 1400)) {
    app$set_window_size(width = width, height = 844)
    app$wait_for_idle()
    phone <- width < 576
    if (phone) {
      testthat::expect_lte(
        app$get_js(
          "document.querySelector('.navbar').getBoundingClientRect().height"
        ),
        80
      )
      testthat::expect_true(app$get_js(
        "(() => { const brand = document.querySelector('.navbar-brand').getBoundingClientRect(); const link = document.querySelector('.github-link').getBoundingClientRect(); return link.width >= 44 && link.height >= 44 && Math.abs((brand.top + brand.bottom) / 2 - (link.top + link.bottom) / 2) < 2; })()"
      ))
    }
    testthat::expect_equal(
      app$get_js(
        "document.querySelector('.app-logo').getBoundingClientRect().height"
      ),
      if (phone) 48 else 72
    )
    for (id in c(
      "trends",
      "daily_values",
      "records",
      "overview",
      "stations",
      "about"
    )) {
      select_tab(id)
      fits_viewport()
    }
    select_tab("stations")
    testthat::expect_equal(
      app$get_js(
        "parseFloat(getComputedStyle(document.querySelector('.stations-map-body')).minHeight)"
      ),
      if (phone) 500 else 600
    )
    set_sidebar("navigation_sidebar", TRUE)
    app$click("show_contact")
    app$wait_for_js(
      "document.querySelector('.contact-modal.show .bslib-grid-item')?.getBoundingClientRect().width > 0"
    )
    app$wait_for_idle()
    app$wait_for_js(sprintf(
      "(() => { const items = document.querySelectorAll('.contact-modal .bslib-grid-item'); return Math.abs(items[0].getBoundingClientRect().top - items[1].getBoundingClientRect().top) %s; })()",
      if (phone) "> 1" else "< 1"
    ))
    testthat::expect_true(app$get_js(sprintf(
      "(() => { const items = document.querySelectorAll('.contact-modal .bslib-grid-item'); return Math.abs(items[0].getBoundingClientRect().top - items[1].getBoundingClientRect().top) %s; })()",
      if (phone) "> 1" else "< 1"
    )))
    fits_viewport()
    app$run_js(
      "document.querySelector('.contact-modal .modal-footer [data-bs-dismiss=\"modal\"]').scrollIntoView({block: 'center'})"
    )
    app$click(
      selector = ".contact-modal .modal-footer [data-bs-dismiss='modal']"
    )
    app$wait_for_js("document.querySelector('.modal.show') === null")
  }
})
