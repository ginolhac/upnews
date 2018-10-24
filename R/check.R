#' fetch news from remote github repo
#'
#' no argument are used
#'
#' @return a data.frame
#'
#' @export
upnews <- function() {
  repos <- get_user_repo(local_gh_pkg())
  remote_sha <- unlist(get_remote_sha1(repos))
  local_sha <- extract_gh_sha1(local_gh_pkg())
  outdated_repos <- compare_sha1(local_sha, remote_sha)
  message(paste(length(outdated_repos), "outdated pkgs, fetching news..."))
  if (length(outdated_repos) == 0) {
    return(
      data.frame(
        pkgs = character(0),
        local = character(0),
        remote = character(0),
        news = character(0), stringsAsFactors = FALSE)
      )
  }
  news <- unlist(lapply(repos[outdated_repos], fetch_news))
  df_news <- data.frame(
    pkgs = outdated_repos,
    local = local_version(local_gh_pkg()[outdated_repos]),
    remote = remote_version(repos[outdated_repos], remote_sha[outdated_repos]),
    news = news, stringsAsFactors = FALSE)
  # trick to get tibble output without dependencies by Eric Koncina
  class(df_news) <- c("tbl_df", "tbl", "data.frame")
  if (requireNamespace("tibble", quietly = TRUE)) library(tibble)
  df_news
}



