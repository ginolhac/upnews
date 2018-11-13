#' fetch news from remote github repo
#'
#' @param debug boolean for displaying installed gh
#'
#' @return a data.frame
#'
#' @export
upnews <- function(debug = FALSE) {
  gh_pkg <- local_gh_pkg()
  repos <- get_user_repo(gh_pkg)
  if (debug) print(repos)
  # FIXME extract_gh should return user/repo
  # clash if 2 users have same repo name
  local_sha <- extract_gh_sha1(gh_pkg)
  local_vers <- extract_version(gh_pkg)
  # unlist unless I found a vapply with progress bar
  remote_sha <- unlist(get_remote_sha1(repos))
  outdated_repos <- compare_sha1(local_sha, remote_sha)
  message(paste0(length(outdated_repos),
                 " outdated pkgs (", length(gh_pkg)," gh pkgs)"))
  if (length(outdated_repos) == 0) {
    df_news <- empty_df()
  } else {
    message("fetching news...")
    news <- unlist(lapply(repos[outdated_repos], fetch_news))
    remote_vers <- unlist(lapply(repos[outdated_repos], fetch_desc))
    df_news <- data.frame(
      pkgs = trim_ref(repos[outdated_repos]),
      loc_version = local_vers[outdated_repos],
      gh_version = remote_vers,
      local = local_version(gh_pkg[outdated_repos]),
      remote = remote_version(repos[outdated_repos], remote_sha[outdated_repos]),
      date = get_last_date(repos[outdated_repos], remote_sha[outdated_repos]),
      news = news, stringsAsFactors = FALSE)
  }
  attr(df_news, "gh_pkg") <- length(gh_pkg)
  # trick to get tibble output without dependencies by Eric Koncina
  class(df_news) <- c("tbl_df", "tbl", "data.frame")
  if (requireNamespace("tibble", quietly = TRUE)) requireNamespace("tibble")
  df_news
}



