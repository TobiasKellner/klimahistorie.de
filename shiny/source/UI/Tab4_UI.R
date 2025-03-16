Tab4_UI_function <- function() {

  tabItem(
    "tab4",
    fluidRow(
      column(
        2,
        style = "
        background-color: #007bff1a;
        padding: 10px;
        border-radius: 5px;
        ",
        dateInput("date_dayhistory", "Tag auswhälen", language = "de", weekstart = 1, format = "dd.mm.yyyy"),
        selectInput("variable_dayhistory", HTML(paste("<b>","Variable auswählen:","</b>")),c(
          "Lufttemperatur",
          "Schneehoehe",
          "Sonnenscheindauer",
          "Niederschlagshoehe"
        ), selected = "Durchschnittstemperatur"),
        radioButtons("average1",
                     "Durchschnitt anzeigen:",
                     c("Ja" = TRUE, "Nein" = FALSE),
                     selected = FALSE,
                     inline = TRUE),
        radioButtons("sort4",
                     "Absteigend sortieren:",
                     c("Ja" = TRUE, "Nein" = FALSE),
                     selected = FALSE,
                     inline = TRUE)
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
