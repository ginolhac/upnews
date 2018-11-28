local({
  if (RStudio.Version()[["version"]] < "1.1.57") {
    stop("RStudio version >= 1.1.57 is required", call. = FALSE)
  }

  stopifnot(
    requireNamespace("miniUI"),
    requireNamespace("shiny"),
    requireNamespace("shinycssloaders"),
    requireNamespace("DT")
  )

  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("NEWS of outdated github packages",
                           left = NULL, # remove the cancel button
                           # from https://github.com/gadenbuie/regexplain/blob/master/R/regex_help.R
                           right = miniUI::miniTitleBarButton("done", "Close", TRUE)
    ),
    miniUI::miniContentPanel(
      shinycssloaders::withSpinner(DT::DTOutput("table"),
                                   proxy.height = "200px"),
      shiny::wellPanel(
        shiny::fluidRow(
          # JS code from Antoine Guillot
          # https://github.com/AntoineGuillot2/ButtonsInDataTable
          shiny::tags$script("$(document).on('click', '#table button', function () {
                    Shiny.onInputChange('lastClickId',this.id);
                    Shiny.onInputChange('lastClick', Math.random())});"),
          shiny::column(4, shiny::checkboxInput("deps", "dependencies = TRUE")),
          shiny::column(4,
                        shiny::actionButton("install", "Update",
                                            style = "color: #fff; background-color: #337ab7; border-color: #2e6da4",
                                            icon = shiny::icon("pause"),
                                            width = "100%")
          ),
          shiny::column(4, shiny::actionButton("refresh", "refresh",
                                               icon = shiny::icon("sync-alt"),
                                               width = "100%")
          )
        )
      )
    )
  )
  server <- function(input, output, session) {

    values <- shiny::reactiveValues(data = NULL,
                                    gh_pkg = NULL)

    gadgetized_table <- function(up) {
      # when all is up-to-date, just return the empty tibble
      if (nrow(up) == 0) {
        return(up)
      }
      pkgs <- vapply(up$pkgs, function(x) strsplit(x, split = "/")[[1]][2], character(1))
      # click on links should not trigger row selection
      # thanks to https://stackoverflow.com/a/51146489/1395352
      stop_propagation <- "' target='_blank' onmousedown='event.preventDefault(); event.stopPropagation(); return false;';>"
      pkgs <- paste0("<a href='https://github.com/",
                     up$pkgs, stop_propagation,
                     pkgs,
                     "</a>")
      up$repo <- up$pkgs
      up$pkgs <- pkgs
      up$news <- paste0('<div onmousedown="event.preventDefault(); event.stopPropagation(); return false;";>
<button type="button" class="btn btn-primary render" id=',
                        paste(up$repo, up$news, sep = "@"), '>NEWS</button></div>')
      up
    }


    output$table <- DT::renderDT({
      # fetch only once data
      if (is.null(values$data)) values$data <- upnews::upnews()
      values$gh_pkg <- attributes(values$data)$gh_pkg
      DT <- gadgetized_table(values$data)
      DT
    },
    escape = FALSE,
    rownames = FALSE,
    class = "cell-border stripe",
    options = list(
      # align center for all columns
      columnDefs = list(list(className = "dt-center", targets = "_all"),
                        # hide some columns
                        list(visible = FALSE, targets = c(3, 4, 7))),
      # display info summary, table, and pagination.
      # Not filtering and length control
      dom = "itp",
      # from https://github.com/daattali/addinslist
      language = list(
        zeroRecords = paste0("up-to-date (", values$gh_pkg, " gh pkgs)"),
        info = paste("_TOTAL_ outdated /", values$gh_pkg),
        infoFiltered = "",
        infoPostFix = " (click any row to select)",
        infoEmpty = "",
        search = "",
        searchPlaceholder = "Search..."
      ),
      # pop hover ref/commit for local and remote versions
      # thanks to SBista https://stackoverflow.com/a/40634033/1395352
      rowCallback = DT::JS(
        "function(nRow, aData, iDisplayIndex, iDisplayIndexFull) {",
        "$('td:eq(0)', nRow).attr('title', aData[7]);",
        "$('td:eq(1)', nRow).attr('title', aData[3]);",
        "$('td:eq(2)', nRow).attr('title', aData[4]);",
        "}")
    )
    )
    # idea from Victor Perrier and code modified from Antoine Guillot
    # https://github.com/AntoineGuillot2/ButtonsInDataTable
    news_modal <- function(clic) {
      titre <- strsplit(clic, "@")[[1]][1]
      url <- strsplit(clic, "@")[[1]][2]
      msg <- ifelse(url == "NA", "<h2>no news</h2>", includeMarkdown(path = url))
      modalDialog(
        title = titre,
        HTML(msg),
        easyClose = TRUE,
        footer = NULL
      )
    }
    observeEvent(input$lastClick, {
      showModal(news_modal(input$lastClickId))
    })

    shiny::observeEvent(input$refresh, {
      session$reload()
    })
    # return number of selected lines
    nb_selected <- shiny::eventReactive(input$table_rows_selected, {
      length(input$table_rows_selected)
    })
    # be default, ignoreNULL is TRUE, Victor Perrier pointed me out this option
    # so when all rows are deselected, NULL value is also triggered
    shiny::observeEvent(input$table_rows_selected, ignoreNULL = FALSE, {
      if (is.null(input$table_rows_selected)) {
        shiny::updateActionButton(session, "install", "Update",
                                  icon = shiny::icon("pause"))
      } else {
        shiny::updateActionButton(session, "install",
                                  paste("Update", nb_selected(), "package(s)"),
                                  icon = shiny::icon("download"))
      }
    })
    shiny::observeEvent(input$install, ignoreNULL = FALSE, {
      # warning is nothing is selected but only when selection has occured
      if (is.null(input$table_rows_selected) && !is.null(input$table_row_last_clicked)) {
        rstudioapi::showDialog("Warning",
                               "Nothing is selected")
        return(NULL)
      }
      plural <- ifelse(nb_selected() == 1, "package", "packages")
      if (!requireNamespace("remotes", quietly = TRUE)) {
        rstudioapi::showDialog("Error",
                               "Remotes is not installed",
                               "https://github.com/r-lib/remotes")
        return(NULL)
      } else {
        if (!rstudioapi::showQuestion(title = "Confirm", ok = "OK",
                                      cancel = "Cancel",
                                      paste0("Are you sure you want to update ",
                                             nb_selected(), " ", plural, "?"))) {
          return(NULL)
        }
        current <- gadgetized_table(values$data)
        split_at <- function(x) strsplit(x, split = "@")[[1]][1]
        repo <- current$repo[input$table_rows_selected]
        refs <- vapply(current$remote[input$table_rows_selected], split_at, character(1))
        to_upgrade <- paste(repo, refs, sep = "@")
        shiny::showModal(shiny::modalDialog(HTML(paste(to_upgrade, collapse = "</br>")),
                                            title = "Upgrading...",
                                            size = "l",
                                            footer = NULL))
        if (input$deps) {
          utils::getFromNamespace("install_github", "remotes")(to_upgrade, upgrade = "never", dependencies = TRUE)
        } else {
          utils::getFromNamespace("install_github", "remotes")(to_upgrade, upgrade = "never")
        }
        shiny::removeModal()
        # remove installed packages
        values$data <- values$data[-input$table_rows_selected, ]
      }
    })

    shiny::observeEvent(input$done, {
      shiny::stopApp()
    })
  }
  shiny::runGadget(ui, server,
                   viewer = shiny::dialogViewer("upnews", width = 800, height = 600))

})
