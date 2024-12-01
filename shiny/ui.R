ui <- bs4DashPage(

  header = dashboardHeader(status = "primary",
    title = "Klimahistorie.de"
    ),

  sidebar = dashboardSidebar(status = "primary",

    menuItem(text = "test1", icon = icon("chart-simple"), badgeColor = "primary"),
    bs4SidebarMenuItem(
      text = "Durchschnitte & Trends",
      icon = icon("chart-simple")
    ),
    bs4SidebarMenuItem(
      text = "Wie war das Wetter wann & wo?",
      icon = icon("map-marked-alt")
    ),
  ),

  body = dashboardBody(),

  controlbar = dashboardControlbar(

    box(
      title = "Standort",
      width = 12,
      icon = icon("location-dot"),
      status = "primary",
      selectizeInput(
        "selectStandort",
        "Standort auswählen:",
        choices = c("Berlin", "Hamburg")
      )
    )

  )

  )
