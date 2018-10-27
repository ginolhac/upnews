local({
  if (RStudio.Version()[["version"]] < "1.1.57") stop("RStudio version >= 1.1.57 is required", call. = FALSE)


  stopifnot(requireNamespace("miniUI"), requireNamespace("shiny"))

  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("NEWS of outdated github packages",
                           left = NULL, # remove the cancel button
                           # from https://github.com/gadenbuie/regexplain/blob/master/R/regex_help.R
                           right = miniUI::miniTitleBarButton("done", "Close", TRUE)
    ),
    miniUI::miniContentPanel(
      DT::DTOutput("table"),
      miniUI::miniButtonBlock(
        shiny::actionButton("install", "Install checked pkgs",
                            style = "text-align: center; color: #fff; background-color: #337ab7; border-color: #2e6da4",
                            icon = shiny::icon("download"), width = "200px")
      )
    )
  )

  server <- function(input, output, session) {
    up <- reactive({
      up <- upnews()
      up$news <- ifelse(!is.na(up$news), paste0("<a href='", up$news,"' target='_blank'>NEWS</a>"), "none")
      up
    })


    output$table <- DT::renderDT({
      up()
    }, escape = FALSE)
    shiny::observeEvent(input$install, {
      nb_selected <- input$table_rows_selected
      if ( length(nb_selected) == 0 ) {
        rstudioapi::showDialog("Warning",
                               "Nothing is selected. Select line(s) by clicking on it (them)\n")
        return()
      }
      if ( !requireNamespace("remotes", quietly = TRUE)) {
        rstudioapi::showDialog("Error", "Remotes is not installed", "https://github.com/r-lib/remotes")
        return()
      } else {
        if (!rstudioapi::showQuestion(title = "Confirm", ok = "OK",
                                      cancel = "Cancel", paste("Are you sure you want to update",
                                                               length(nb_selected),
                                                               ifelse(nb_selected == 1, "package?", "packages?")))) return()
        split_at <- function(x) strsplit(x, split = "@")[[1]][1]
        pkgs <- vapply(up()$local[input$table_rows_selected], split_at, character(1))
        refs <- vapply(up()$remote[input$table_rows_selected], split_at, character(1))
        utils::getFromNamespace("install_github", "remotes")(paste(pkgs, refs, sep = "@"))
      }
    })
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
