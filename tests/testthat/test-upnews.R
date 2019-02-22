context("basic functionality")
# based on https://github.com/hrbrmstr/dtupdate/tree/master/tests/testthat
test_that("we can run the function and get back a dat frame", {
  un <- upnews()
  expect_that(upnews(), is_a("data.frame"))
  expect_equal(colnames(un), c("pkgs", "loc_version", "gh_version",
                              "local", "remote", "date", "news"))
})

context("utils")

test_that("without github API", {
  pkgs <- readRDS(system.file("test", "outdated_pks.rds",
                              package = "upnews", mustWork = TRUE))
  reps <- c(bifag = "ginolhac/bifag/d490355",
            karate = "farina/karate/master",
            credentials = "jeroen/credentials/c9a41977adfd415075c18744186bcc7f30bfcc4c")
  shas <- c(bifag = "362992a662f529709aa4a1063cad798c525f31ee",
            karate = "1234567",
            credentials = "64c4a565cf678c8d28fcd7155d76960840078ac0")
  shas2 <- c(bifag = "362992a662f529709aa4a1063cad798c525f31ee",
            karate = "1234568",
            credentials = "64c4a565cf678c8d28fcd7155d76960840078acc")
  bad_sha <- c(bifag = "362992a662f529709aa4a1063cad798c525f31ee",
               karatee = "1234567",
               credentials = "64c4a565cf678c8d28fcd7155d76960840078ac0")
  expect_equal(slash_split(reps[2]), list(user = "farina",
                                          repo = "karate",
                                          ref = "master"))
  expect_equal(remote_version(reps, shas), c("d490355@362992a",
                                             "d490355@1234567",
                                             "d490355@64c4a56"))
  expect_error(remote_version(reps, bad_sha), "names differs")
  expect_equal(local_version(reps, shas), c(bifag = "d490355@362992a",
                                            karate = "master@1234567",
                                      credentials = "c9a41977adfd415075c18744186bcc7f30bfcc4c@64c4a56"
  ))
  expect_equal(get_user_repo(pkgs), c(bifag = "ginolhac/bifag/d490355",
                                      credentials = "jeroen/credentials/c9a41977adfd415075c18744186bcc7f30bfcc4c"))
  expect_equal(extract_version(pkgs), c(bifag = "0.1.3.990", credentials = "0.1"))
  expect_equal(extract_gh_sha1(pkgs), c(bifag = "d490355117025d1be7a237276b1db73283e3d1a9",
                                        credentials = "c9a41977adfd415075c18744186bcc7f30bfcc4c"))
  expect_error(compare_sha1(shas, bad_sha), "vectors differ")
  expect_equal(compare_sha1(shas, shas2), c("karate", "credentials"))
  expect_equal(trim_ref(reps), c(bifag = "ginolhac/bifag",
                                 karate = "farina/karate",
                                 credentials = "jeroen/credentials"))
  expect_equal(empty_df(), structure(list(pkgs = character(0),
                                          loc_version = character(0),
                                          gh_version = character(0),
                                          local = character(0),
                                          remote = character(0),
                                          date = character(0),
                                          news = character(0)),
                                     class = "data.frame",
                                     row.names = integer(0)))
  expect_equal(slash_split("repo/contents/DESCRIPTION"),
               list(user = "repo", repo = "contents", ref = "DESCRIPTION"))
  expect_error(slash_split("repo/contents"))
  expect_equal(validate_branche(slash_split("ginolhac/upnews/master")), "master")
  expect_equal(validate_branche(slash_split("ginolhac/upnews/masterrr")), "dev")

})

test_that("GitHub API queries", {

  skip_on_cran()

  # skip offline
  # using dormant rescueMisReadIndex repo
  expect_equal(get_remote_sha1("ginolhac/rescueMisReadIndex/master")[[1]],
               "253f47a6da1f8209eee4f97f83b2151b4b155b63")
  expect_equal(get_last_date("ginolhac/rescueMisReadIndex/master", "253f47a6da1f8209eee4f97f83b2151b4b155b63"),
               c(`ginolhac/rescueMisReadIndex/master` = "2013-06-12"))
  expect_equal(get_last_date("ginolhac/rescueMisReadIndex/master", "253f47a"),
               c(`ginolhac/rescueMisReadIndex/master` = "2013-06-12"))
  expect_true(is_on_branch(slash_split("ginolhac/upnews/ac1b768"), "master"))
  expect_false(is_on_branch(slash_split("ginolhac/upnews/ac1b768"), "dev"))
  expect_equal(gh_fix_ref("ginolhac/upnews/master"), "ginolhac/upnews/master")
  expect_equal(gh_fix_ref("ginolhac/upnews/ac1b768"), "ginolhac/upnews/master")
  expect_equal(gh_fix_ref("ginolhac/upnews/31a5300"), "ginolhac/upnews/dev")
  expect_equal(gh_fix_ref("r-lib/usethis/ed9ae17"), "r-lib/usethis/master") # for #8
  expect_equal(fetch_news("ginolhac/rescueMisReadIndex/master"), NA)
  expect_equal(fetch_news("ginolhac/upnews/master"),
               "https://raw.githubusercontent.com/ginolhac/upnews/master/NEWS.md")
  # version must be only letters and dot
  expect_true(grepl("^[0-9\\.]+$", fetch_desc("ginolhac/upnews/master")))
})

# from https://github.com/r-lib/remotes/blob/master/tests/testthat/test-install-github.R
# L54
test_that("github_release", {

  skip_on_cran()
  #skip_if_offline()

  Sys.unsetenv("R_TESTS")

  lib <- tempfile()
  on.exit(unlink(lib, recursive = TRUE), add = TRUE)
  dir.create(lib)

  remotes::install_github(
    "gaborcsardi/falsy",
    # get outdated version
    ref = "2db22022d08cad450aa2d9325cc3bb1ac88c5eba",
    lib = lib,
    quiet = TRUE
  )

  expect_silent(packageDescription("falsy", lib.loc = lib))
  expect_equal(packageDescription("falsy", lib.loc = lib)$RemoteRepo, "falsy")
  # now test upnews, should have only one outdated pkg
  un <- upnews(lib = lib)
  expect_message(upnews(debug = TRUE), "debug:")
  expect_equal(attributes(un)$gh_pkg, 1L)
  expect_equal(attributes(un)$row.names, "falsy")
  expect_equal(nrow(un), 1L)
  expect_equal(un$loc_version, "1.0")
  expect_equal(un$local, "master@2db2202")
  expect_false(un$local == un$remote)
  expect_equal(local_gh(lib = lib), c("gaborcsardi/falsy" = "master@2db2202"))
  # might remove this one if Gabor creates one!
  expect_equal(un$news, NA)
})
