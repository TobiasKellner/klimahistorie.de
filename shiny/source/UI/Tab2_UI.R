Tab2_UI_function <- function() {

  tabItem(
    "tab2",
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
          dateInput(
            "date2",
            HTML(paste("<b>","Datum:","</b>")),
            value = today() - months(1),
            max = today(),
            startview = "decade"
            )
          )
        ),
      column(
        width = 10,
        bs4InfoBox(
          title = uiOutput("description2"),
          icon = icon("info-circle"),
          color = "primary",
          width = 12
        ),
        br(),
        fluidRow(
          valueBoxOutput("box1"),
          valueBoxOutput("box2"),
          valueBoxOutput("box3")
          ),
                 fluidRow(
                   valueBoxOutput("box4"),
                   valueBoxOutput("box5"),
                   valueBoxOutput("box6")
                 ),
                 fluidRow(
                   valueBoxOutput("box7"),
                   valueBoxOutput("box8"),
                   valueBoxOutput("box9")
                 )


          )
          )
  )

}
