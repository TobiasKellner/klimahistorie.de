Tab3_UI_function <- function() {

  tabItem(
    tabName = "tab3",
    fluidRow(
      column(
        2,
        style = "padding: 0px;",

        box(
          collapsible = FALSE,
          title = "Einstellungen",
          width = 12,
          icon = icon("gear"),
          status = "primary",
          solidHeader = TRUE,
          selectInput(
            'variable3',
            HTML(paste("<b>","Variable","</b>")),
            c("Lufttemperatur",
              "Schneehoehe",
              "Sonnenscheindauer",
              "Niederschlagshoehe"
              )
            ),
          selectInput(
            'month3',
            HTML(paste("<b>","Jahr / Monat","</b>")),
            c(month_list),
            selected = "Gesamtes Jahr"
            ),
          selectInput(
            'type',
            HTML(paste("<b>","Art der Grafik","</b>")),
            c(
              c("Linie","Punkte","Balken")
              ),
            selected = "Linie"
            ),
          radioButtons(
            "smooth_trend",
            HTML("Durchschnittsverlauf anzeigen?"),
            c("Ja" = TRUE, "Nein" = FALSE),
            selected = FALSE,
            inline = TRUE
            ),
          textInput("year3", label = HTML(paste("<b>","Jahre","</b>")), value = "2022,2021"),
          "In diesem Feld können mehrere Jahre miteinander verglichen werden. Einfache so viele Jahre wie gewünscht eingeben. Die Jahre müssen durch ein Komma getrennt sein und dürfen kein Leerzeichen enthalten.\ Beispiel:\ 2020,2019,1999,1980"
        )
      ),
      column(
        10,
        bs4InfoBox(
          title = uiOutput("description3"),
          icon = icon("info-circle"),
          color = "primary",
          width = 12
        ),
        withSpinner(plotlyOutput("plot3", height = "calc(100vh - 250px)"))
      )
    )
  )

}
