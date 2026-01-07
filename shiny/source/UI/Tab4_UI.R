Tab4_UI_function <- function() {

  tabItem(
    "tab4",
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
          dateInput("date_dayhistory", "Tag auswhälen", language = "de", weekstart = 1, format = "dd.mm.yyyy"),
          selectInput(
            "variable_dayhistory",
            HTML(paste("<b>","Variable auswählen:","</b>")),
            c(
              "Lufttemperatur",
              "Schneehoehe",
              "Sonnenscheindauer",
              "Niederschlagshoehe"
              ),
            selected = "Durchschnittstemperatur"
            ),
          radioButtons(
            "average1",
            "Durchschnitt anzeigen:",
            c("Ja" = TRUE, "Nein" = FALSE),
            selected = FALSE,
            inline = TRUE
            ),
        radioButtons(
          "sort4",
          "Absteigend sortieren:",
          c("Ja" = TRUE, "Nein" = FALSE),
          selected = FALSE,
          inline = TRUE
          )
        )
      ),
      column(
        10,
        bs4InfoBox(
          title = uiOutput("description4"),
          icon = icon("info-circle"),
          color = "primary",
          width = 12
        ),
        uiOutput("header_text_dayhistory1"),
        plotlyOutput("plot_dayhistory", height = "calc(100vh - 250px)")
          )
      )
    )

}
