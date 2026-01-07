Tab5_UI_function <- function() {

  tabItem(
    tabName = "tab5",
    fluidRow(
      column(
        width = 2,
        style = "padding: 0px;",

        box(
          collapsible = FALSE,
          title = "Einstellungen",
          width = 12,
          icon = icon("gear"),
          status = "primary",
          solidHeader = TRUE,
          radioButtons(
            inputId = "record",
            HTML(paste("<b>","Maximum / Minimum","</b>")),
            c("Maximum" = "Maximum", "Minimum" = "Minimum"),
            selected = "Maximum"
            )
          )
        ),
        column(
              10,
              bs4InfoBox(
                title = uiOutput("description5"),
                icon = icon("info-circle"),
                color = "primary",
                width = 12
              ),
              br(),
              fluidRow(
                valueBoxOutput("records_durchschnittstemperatur"),
                valueBoxOutput("records_minimaltemperatur"),
                valueBoxOutput("records_maximaltemperatur")
              ),
              fluidRow(
                valueBoxOutput("records_sonnenscheindauer"),
                valueBoxOutput("records_niederschlagshoehe"),
                valueBoxOutput("records_schneehoehe")
              ),
              fluidRow(
                valueBoxOutput("records_windgeschwindigkeit"),
                valueBoxOutput("records_windspitze"),
                valueBoxOutput("records_luftdruck")
              )
            )
          )
  )

}
