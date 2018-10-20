
#' upnews, look up for new files for outdated
#' github repositories
#' @export
upnews <- function() {
  repos <- get_user_repo(local_gh_pkg())
  remote_sha <- get_remote_sha1(repos)
  local_sha <- extract_gh_sha1(local_gh_pkg())
  outdated_repos <- compare_sha1(local_sha, remote_sha)
  #repos[outdated_repos]
  news <- lapply(repos[outdated_repos], fetch_news)
  news
}


