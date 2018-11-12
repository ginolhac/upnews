#' @importFrom gh gh
#' @importFrom utils packageDescription
#' @importFrom utils installed.packages
#' @importFrom stats setNames
#' @importFrom pbapply pblapply
NULL

#' extract local github packages
#'
local_gh_pkg <- function() {
  pkgs <- row.names(utils::installed.packages())
  desc <- lapply(setNames(pkgs, nm = pkgs), utils::packageDescription)
  gh_pkg <- vapply(desc, function(x) !is.null(x$GithubSHA1), logical(1))
  desc[gh_pkg]
}

#' extract HEAD sha1sum
#'
#' @param desc pkg description
extract_gh_sha1 <- function(desc) {
  vapply(desc, function(x) x$GithubSHA1, character(1))
}

#' extract Version
#'
#' @param desc pkg description
extract_version <- function(desc) {
  vapply(desc, function(x) x$Version, character(1))
}

#' concatenate user/repo
#'
#' @param desc pkg description
get_user_repo <- function(desc) {
  vapply(desc, function(x) {
    paste0(x$GithubUsername, "/", x$GithubRepo, "/", x$GithubRef)
  }, character(1))
}

#' fetch distant HEAD sha1sum
#'
#' @param repos pkg user/repo
get_remote_sha1 <- function(repos) {
  message("fetching distant sha1")
  pblapply(repos, function(x) {
    rep <- slash_split(x)
    rep$ref <- gh_fix_ref(rep$ref)
    gh("GET /repos/:owner/:repo/git/refs/heads/:ref",
       owner = rep$user, repo = rep$repo, ref = rep$ref)[["object"]][["sha"]]
  })
}


gh_fix_ref <- function(ref) {
  # FIXME refs work only it is a branch
  # list all branchs with:
  # unlist(lapply(gh::gh("GET /repos/ginolhac/upnews/branches"), function(x) x$name))
  # display a commit gh::gh("GET /repos/ginolhac/bifag/commits/d490355")
  if (grepl("[0-9a-f]{7,40}", ref)) {# c("d490355", "master", "dev", "cc2db095e9dcfc52346c1ffeeb84a0e13f12c22a")
    # https://stackoverflow.com/a/468378/1395352
    # deal with a commit, surely, check if it is a ref
    # quick and dirty fix, use master
    ref <- "master"
  }
  ref
}

get_last_date <- function(repos, sha1) {
  mapply(function(rep, sha) {
    rep <- slash_split(rep)
    last_date <- gh("GET /repos/:owner/:repo/commits/:sha",
                    owner = rep$user, repo = rep$repo, sha = sha)$commit$author$date
    format(as.Date(last_date), "%Y-%m-%d")
  }, repos, sha1, SIMPLIFY = TRUE, USE.NAMES = TRUE)
}

#' modified from r-lib/sessioninfo licence GPL/2
#'
#' @param desc pkg description
#'
local_version <- function(desc) {
  vapply(desc, function(x) paste0(
    #FIXME when ref is a commit
    x$GithubRef, "@",
    substr(x$GithubSHA1, 1, 7), ")"), character(1))
}

trim_ref <- function(repos) {
  vapply(repos, function(x) {
    paste(strsplit(x, "/")[[1]][1:2], collapse = "/")
  }, character(1))
}


#' fetch distant news file
#'
#' @param repos pkg user/repo
#'
fetch_news <- function(repos) {
  #TODO
  # - look recursively in the tree or only the root? check for the 37 repos
  # - deal with several positive answers, rank by extension
  # query the files/folder at repo root
  rep <- slash_split(repos)
  rep$ref <- gh_fix_ref(rep$ref)
  gh_list <- gh("GET /repos/:owner/:repo/contents/:path/?ref=:ref",
                    owner = rep$user, repo = rep$repo, path = ".", ref = rep$ref)
  # extract the flatten chr list
  remote_list <- vapply(gh_list, "[[", "", "name")
  # look for a news files
  # TODO might need to look for more than news.md / NEWS.md
  news_idx <- grep("news\\.md", remote_list, ignore.case = TRUE)
  if (length(news_idx) == 0) {
    message(paste("no news for", repos))
    return(NA)
  } else if (length(news_idx) > 1) {
    message(paste("multiple news for", repos))
    # give chance
  } else {
    remote_list[news_idx]
    # get download url and read news files
    gh_list[[news_idx]]$download_url
  }
}

slash_split <- function(repos) {
  user <- strsplit(repos, "/")[[1]][1]
  repo <- strsplit(repos, "/")[[1]][2]
  ref <- strsplit(repos, "/")[[1]][3]
  list(user = user,
       repo = repo,
       ref = ref)
}

fetch_desc <- function(repos) {
  rep <- slash_split(repos)
  rep$ref <- gh_fix_ref(rep$ref)
  gh_desc <- gh("GET /repos/:owner/:repo/contents/DESCRIPTION/?ref=:ref",
                    owner = rep$user, repo = rep$repo, path = ".", ref = rep$ref)
  desc <- readLines(gh_desc$download_url)
  version <- desc[grep("^Version:", desc)]
  strsplit(version, " ")[[1]][2]
}

#' compare 2 vectors
#'
#' @param a first vector of repo names
#' @param b second vector of repo names
#'
compare_sha1 <- function(a, b) {
  if (sum(names(a) != names(b)) > 0) stop("vectors differ", call. = FALSE)
  names(a[a != b])
}

#' build remote version, ref and short sha1
#'
#' @param ref vector of repo ref
#' @param sha vector of sha1sum
#'
remote_version <- function(ref, sha) {
  if (sum(names(ref) != names(sha)) > 0) stop("names differs", call. = FALSE)
  ref <- strsplit(ref, "/")[[1]][3]
  paste0(ref, "@",
         substr(sha, 1, 7))
}