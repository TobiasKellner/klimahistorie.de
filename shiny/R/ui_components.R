app_logo_ui <- function() {
  shiny::tags$span(
    class = "app-logo",
    shiny::tags$img(src = "logo.png", alt = "Klimahistorie.de")
  )
}

filter_card_ui <- function(
  title,
  sidebar_id,
  controls,
  content,
  full_screen = FALSE
) {
  bslib::card(
    full_screen = full_screen,
    bslib::card_header(title),
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        id = sidebar_id,
        open = "desktop",
        bg = "#F8F9FA",
        controls
      ),
      content
    )
  )
}

navigation_sidebar_ui <- function(navigation = app_navigation()) {
  panels <- lapply(seq_len(nrow(navigation)), function(i) {
    bslib::nav_panel(
      navigation$label[[i]],
      value = navigation$id[[i]],
      icon = shiny::icon(navigation$icon[[i]], class = "fa-fw")
    )
  })
  bslib::sidebar(
    id = "navigation_sidebar",
    open = "desktop",
    bg = "#FFFFFF",
    width = 260,
    shiny::tags$div(
      class = "sidebar-navigation",
      do.call(bslib::navset_pill, c(panels, list(id = "sidebar_tabs")))
    ),
    shiny::tags$div(
      class = "sidebar-contact",
      bslib::tooltip(
        shiny::actionButton(
          "show_contact",
          "Kontakt",
          icon = shiny::icon("hand-pointer"),
          class = "btn-danger w-100"
        ),
        shiny::tags$strong("Werbung in eigener Sache:"),
        " Benötigen Sie Hilfe im Bereich Datenanalyse? Schreiben Sie mir eine Nachricht!",
        placement = "top"
      )
    )
  )
}
