#' @importFrom git2r remote_ls
#' @importFrom gh gh
#' @importFrom utils type.convert
#' @importFrom stats setNames

local_gh_pkg <- function() {
  pkgs <- row.names(installed.packages())
  desc <- lapply(setNames(pkgs, nm = pkgs), utils::packageDescription)
  gh_pkg <- vapply(desc, function(x) !is.null(x$GithubSHA1), logical(1))
  desc[gh_pkg]
}

extract_gh_sha1 <- function(desc) {
  vapply(desc, function(x) x$GithubSHA1, character(1))
}

get_user_repo <- function(desc) {
  vapply(desc, function(x) paste0(x$GithubUsername, "/", x$GithubRepo), character(1))
}
repos <- get_user_repo(local_gh_pkg())

get_remote_sha1 <- function(meta) {
  vapply(meta, function(x) {
    git2r::remote_ls(paste0("https://github.com/", x))["HEAD"]
  }, character(1))
}
remote_sha <- get_remote_sha1(repos)
local_sha <- extract_gh_sha1(local_gh_pkg())

compare_sha1 <- function(a, b) {
  if (sum(names(a) != names(b)) > 0) stop("vectors differ", call. = FALSE)
  names(a[a != b])
}

outdated_repos <- compare_sha1(local_sha, remote_sha)

repos[outdated_repos]
#TODO
# - turn this into a function
# - look recursively in the tree or only the root? check for the 37 repos
# - deal with several positive answers, rank by extension
# query the files/folder at repo root
fetch_news <- function(repos) {
  user <- strsplit(repos, "/")[[1]][1]
  repo <- strsplit(repos, "/")[[1]][2]
  gh_list <- gh::gh("GET /repos/:owner/:repo/contents/:path",
                      owner = user, repo = repo, path = ".")
  # extract the flatten chr list
  remote_list <- vapply(gh_list, "[[", "", "name")
  # look for a new files
  news_idx <- grep("news", remote_list, ignore.case = TRUE)
  if (length(news_idx) == 0) {
    message(paste("no news for", repos))
    return(NULL)
  } else if (length(news_idx) > 1) {
    message(paste("multiple news for", repos))
    return(Inf)
  } else {
    remote_list[news_idx]
    # get download url and read news files
    readLines(gh_list[[news_idx]]$download_url)
  }
}
news <- lapply(repos[outdated_repos], fetch_news)

