#' @importFrom tibble tibble
NULL

#' fetch news from remote github repo
#'
#' no argument are used
#'
#' @return a tibble
#'
#' @export
upnews <- function() {
  repos <- get_user_repo(local_gh_pkg())
  remote_sha <- unlist(get_remote_sha1(repos))
  local_sha <- extract_gh_sha1(local_gh_pkg())
  outdated_repos <- compare_sha1(local_sha, remote_sha)
  message(paste(length(outdated_repos), "outdated pkgs, fetching news..."))
  #repos[outdated_repos]
  news <- lapply(repos[outdated_repos], fetch_news)
  tibble::tibble(
    pkgs = outdated_repos,
    local = local_version(local_gh_pkg()[outdated_repos]),
    remote = paste0("@", substr(remote_sha[outdated_repos], 1, 7)),
    news = news)
}



