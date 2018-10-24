# The addin should be optional: Using the same trick as in
# the bookdown mathquill addin to load it as an external script
upnews_ui <- function() {
  sys.source(system.file("scripts", "upnews.R", package = "upnews", mustWork = TRUE),
             new.env())
}