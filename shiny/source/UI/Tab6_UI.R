Tab6_UI_function <- function() {

  tabItem(
    "tab6",
    fluidRow(
      column(
        2,
        style = "
        background-color: #007bff1a;
        padding: 10px;
        border-radius: 5px;
        ",
        selectInput(
          'ycol_over',
          HTML(paste("<b>","Variable","</b>")),
          c(
            "Lufttemperatur",
            "Schneehoehe",
            "Sonnenscheindauer",
            "Niederschlagshoehe"
          ),
          selected = "Lufttemperatur"
        ),
        radioButtons(
          "auswahl",
          "Tage über / Tage unter",
          c("Über" = TRUE, "Unter" = FALSE),
          selected = TRUE,
          inline=T
        ),
        radioButtons(
          "current_year6",
          HTML("<b>Aktuelles Jahr anzeigen?</b>"),
          c("Ja" = TRUE,
            "Nein" = FALSE),
          selected = FALSE,
          inline = T
        ),
        uiOutput("over_sliderinput")
      ),
      column(
        10,
        bs4InfoBox(
          title = uiOutput("description6"),
          icon = icon("info-circle"),
          color = "primary",
          width = 12
        ),
        plotlyOutput("plot_over_1", height = "80vh")
      )
    )
  )

}
