app_ui <- function(app_dir = ".") {
  navigation <- app_navigation()
  views <- list(
    trends = mod_trends_ui("trends"),
    daily_values = mod_daily_values_ui("daily_values"),
    year_comparison = mod_year_comparison_ui("year_comparison"),
    daily_history = mod_daily_history_ui("daily_history"),
    records = mod_records_ui("records"),
    thresholds = mod_thresholds_ui("thresholds"),
    stations = view_stations_ui(),
    about = view_about_ui()
  )
  panels <- lapply(navigation$id, function(id) {
    bslib::nav_panel_hidden(id, views[[id]])
  })
  do.call(
    bslib::page_navbar,
    c(
      list(
        id = "main_tabs",
        selected = navigation$id[[1]],
        window_title = "Klimahistorie.de",
        title = app_logo_ui(),
        theme = app_theme(),
        navbar_options = bslib::navbar_options(
          class = "bg-primary",
          theme = "dark",
          collapsible = FALSE
        ),
        header = shiny::tagList(
          shiny::tags$head(
            shiny::tags$link(
              rel = "icon",
              type = "image/png",
              href = "favicon.png"
            )
          ),
          shiny::includeCSS(file.path(app_dir, "www", "custom.css")),
          shiny::includeScript(file.path(app_dir, "www", "sidebar-tooltips.js"))
        ),
        sidebar = navigation_sidebar_ui(navigation)
      ),
      panels,
      list(
        bslib::nav_spacer(),
        bslib::nav_item(
          shiny::tags$a(
            class = "nav-link github-link",
            href = "https://github.com/TobiasKellner/klimahistorie.de",
            target = "_blank",
            rel = "noopener noreferrer",
            title = "Repository auf GitHub öffnen",
            `aria-label` = "Repository auf GitHub öffnen",
            shiny::icon("github")
          )
        )
      )
    )
  )
}
