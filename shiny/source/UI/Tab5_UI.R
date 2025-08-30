Tab5_UI_function <- function() {

  tabItem(
    tabName = "tab5",
    fluidRow(
      column(
        width = 2,
        style = "
        background-color: #007bff1a;
        padding: 10px;
        border-radius: 5px;
        ",
        radioButtons(
          inputId = "record",
          HTML(paste("<b>","Maximum / Minimum","</b>")),
                           c("Maximum" = "Maximum",
                             "Minimum" = "Minimum"),
                           selected = "Maximum")
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
