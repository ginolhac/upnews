#' upnews ui
#'
#' in an RStudio
#' viewer pane.
#'
#' @import miniUI
#' @import shiny
#' @export
upnews_ui <- function() {
  stopifnot(requireNamespace("miniUI"), requireNamespace("shiny"))

  ui <- miniPage(
    gadgetTitleBar("NEWS of outdated github packages",
                   # from https://github.com/gadenbuie/regexplain/blob/master/R/regex_help.R
                   right = miniTitleBarButton("done", "OK", TRUE)
    ),
    miniContentPanel(
      dataTableOutput("table")
    )
  )

  server <- function(input, output, session) {
    output$table <- renderDataTable({
      up <- upnews()
      up$news <- ifelse(!is.na(up$news), paste0("<a href='", up$news,"' target='_blank'>NEWS</a>"), "none")
      up
    }, escape = FALSE)
    observeEvent(input$done, {
      stopApp()
    })
    observeEvent(input$cancel, {
      stopApp()
    })
  }
  viewer <- shiny::paneViewer(700)
  runGadget(ui, server, viewer = viewer)
}
