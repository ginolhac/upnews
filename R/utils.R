#' @importFrom gh gh
#' @importFrom utils packageDescription
#' @importFrom utils installed.packages
#' @importFrom stats setNames
#' @importFrom pbapply pblapply
NULL

#' extract local github packages
#'
#' @param lib path to lib
local_gh_pkg <- function(lib) {
  pkgs <- row.names(utils::installed.packages(lib.loc = lib))
  desc <- lapply(setNames(pkgs, nm = pkgs), utils::packageDescription, lib.loc = lib)
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

slash_split <- function(repos) {
  l <- as.list(strsplit(repos, "/")[[1]])
  if (length(l) != 3) stop(paste("missing info in", repos), call. = FALSE)
  names(l) <- c("user", "repo", "ref")
  l
}

#' fetch distant HEAD sha1sum
#'
#' @param repos pkg user/repo
get_remote_sha1 <- function(repos) {
  message(paste("fetching",  length(repos), "distant sha1"))
  pblapply(repos, function(x) {
    rep <- slash_split(x)
    gh("GET /repos/:owner/:repo/git/refs/heads/:ref",
       owner = rep$user, repo = rep$repo, ref = rep$ref)[["object"]][["sha"]]
  })
}


gh_fix_ref <- function(rep) {
  rep <- slash_split(rep)
  # refs work only it is a branch
  # check if ref is commit and fix to replace by the its branch of origin
  # https://stackoverflow.com/a/468378/1395352
  if (grepl("[0-9a-f]{7,40}", rep$ref)) {# c("d490355", "master", "dev", "cc2db095e9dcfc52346c1ffeeb84a0e13f12c22a")
    # procedure as in https://stackoverflow.com/a/23970412/1395352
    # list all branchs with:
    branches <- gh("GET /repos/:owner/:repo/branches", owner = rep$user, repo = rep$repo)
    branch_names <- unlist(lapply(branches, function(x) x$name))
    for (branch in branch_names) {
      #message(paste("testing", branch, rep$ref))
      if (isTRUE(is_on_branch(rep, branch))) {
        new_ref <- branch
        break()
      }
      #else {message("not found")}
    }
  } else new_ref <- rep$ref
  # rebuild string with fixed ref which a branch now
  paste(c(rep$user, rep$rep, new_ref), collapse = "/")
}

is_on_branch <- function(rep, branch) {
  status <- gh("GET /repos/:owner/:repo/compare/:ref...:sha",
               owner = rep$user, repo = rep$repo,
               ref = branch, sha = rep$ref)$status
  if (status %in% c("behind", "identical") ) {
    TRUE
  } else if (status %in% c("diverged", "ahead")) {
    FALSE
  } else {
    # should not happen
    NA_integer_
  }
}

get_last_date <- function(repos, sha1) {
  mapply(function(rep, sha) {
    rep <- slash_split(rep)
    last_date <- gh("GET /repos/:owner/:repo/commits/:sha",
                    owner = rep$user, repo = rep$repo, sha = sha)$commit$author$date
    format(as.Date(last_date), "%Y-%m-%d")
  }, repos, sha1, SIMPLIFY = TRUE, USE.NAMES = TRUE)
}


local_version <- function(rep, sha) {
  mapply(function(rep, sha) {
    ref <- slash_split(rep)$ref
   paste0(ref, "@", substr(sha, 1, 7))
   }, rep, sha, USE.NAMES = TRUE, SIMPLIFY = TRUE)
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
    # message(paste("multiple news for", repos))
    # might be used if grep is only news without extension
  } else {
    remote_list[news_idx]
    # get download url and read news files
    gh_list[[news_idx]]$download_url
  }
}

fetch_desc <- function(repos) {
  rep <- slash_split(repos)
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

empty_df <- function() {
  data.frame(
    pkgs = character(0),
    loc_version = character(0),
    gh_version = character(0),
    local = character(0),
    remote = character(0),
    date = character(0),
    news = character(0), stringsAsFactors = FALSE)
}
