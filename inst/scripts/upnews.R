local({
  if (RStudio.Version()[["version"]] < "1.1.57") stop("RStudio version >= 1.1.57 is required", call. = FALSE)


  stopifnot(requireNamespace("miniUI"), requireNamespace("shiny"))

  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("NEWS of outdated github packages",
                           # from https://github.com/gadenbuie/regexplain/blob/master/R/regex_help.R
                           right = miniUI::miniTitleBarButton("done", "OK", TRUE)
    ),
    miniUI::miniContentPanel(
      dataTableOutput("table")
    )
  )

  server <- function(input, output, session) {
    output$table <- renderDataTable({
      up <- upnews()
      up$news <- ifelse(!is.na(up$news), paste0("<a href='", up$news,"' target='_blank'>NEWS</a>"), "none")
      up
    }, escape = FALSE)
    shiny::observeEvent(input$done, {
      shiny::stopApp()
    })
    shiny::observeEvent(input$cancel, {
      shiny::stopApp()
    })
  }
  #viewer <- shiny::paneViewer(700)
  shiny::runGadget(ui, server, viewer = shiny::dialogViewer("upnews", width = 800, height = 600))

})
