#' @importFrom git2r remote_ls
#' @importFrom gh gh
#' @importFrom utils packageDescription
#' @importFrom utils installed.packages
#' @importFrom stats setNames
NULL

#' extract local github packages
local_gh_pkg <- function() {
  pkgs <- row.names(utils::installed.packages())
  desc <- lapply(setNames(pkgs, nm = pkgs), utils::packageDescription)
  gh_pkg <- vapply(desc, function(x) !is.null(x$GithubSHA1), logical(1))
  desc[gh_pkg]
}

#' extract HEAD sha1sum
#' @param desc pkg description
extract_gh_sha1 <- function(desc) {
  vapply(desc, function(x) x$GithubSHA1, character(1))
}

#' concatenate user/repo
#' @param desc pkg description
get_user_repo <- function(desc) {
  vapply(desc, function(x) paste0(x$GithubUsername, "/", x$GithubRepo), character(1))
}

#' fetch distant HEAD sha1sum
#' @param meta pkg user/repo
get_remote_sha1 <- function(meta) {
  vapply(meta, function(x) {
    git2r::remote_ls(paste0("https://github.com/", x))["HEAD"]
  }, character(1))
}

#' fetch distant news file
#' @param repos pkg user/repo
fetch_news <- function(repos) {
  #TODO
  # - turn this into a function
  # - look recursively in the tree or only the root? check for the 37 repos
  # - deal with several positive answers, rank by extension
  # query the files/folder at repo root
  user <- strsplit(repos, "/")[[1]][1]
  repo <- strsplit(repos, "/")[[1]][2]
  gh_list <- gh::gh("GET /repos/:owner/:repo/contents/:path",
                    owner = user, repo = repo, path = ".")
  # extract the flatten chr list
  remote_list <- vapply(gh_list, "[[", "", "name")
  # look for a new files
  news_idx <- grep("news\\.md", remote_list, ignore.case = TRUE)
  if (length(news_idx) == 0) {
    message(paste("no news for", repos))
    return(NULL)
  } else if (length(news_idx) > 1) {
    message(paste("multiple news for", repos))
    # give chance
  } else {
    remote_list[news_idx]
    # get download url and read news files
    readLines(gh_list[[news_idx]]$download_url)
  }
}

#' compare 2 vectors
#' @param a first vector of repo names
#' @param b second vector of repo names
compare_sha1 <- function(a, b) {
  if (sum(names(a) != names(b)) > 0) stop("vectors differ", call. = FALSE)
  names(a[a != b])
}