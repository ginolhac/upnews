context("basic functionality")
# based on https://github.com/hrbrmstr/dtupdate/tree/master/tests/testthat
test_that("we can run the function and get back a dat frame", {
  expect_that(upnews(), is_a("data.frame"))
})

context("utils")

test_that("without github API", {
  pkgs <- readRDS(system.file("test", "outdated_pks.rds", package = "upnews", mustWork = TRUE))
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
  expect_equal(slash_split(reps[2]), list(user = "farina", repo = "karate", ref = "master"))
  expect_equal(remote_version(reps, shas), c("d490355@362992a", "d490355@1234567", "d490355@64c4a56"))
  expect_error(remote_version(reps, bad_sha), "names differs")
  expect_equal(get_user_repo(pkgs), c(bifag = "ginolhac/bifag/d490355",
                                      credentials = "jeroen/credentials/c9a41977adfd415075c18744186bcc7f30bfcc4c"))
  expect_equal(extract_version(pkgs), c(bifag = "0.1.3.990", credentials = "0.1"))
  expect_equal(extract_gh_sha1(pkgs), c(bifag = "d490355117025d1be7a237276b1db73283e3d1a9",
                                        credentials = "c9a41977adfd415075c18744186bcc7f30bfcc4c"))
  expect_error(compare_sha1(shas, bad_sha), "vectors differ")
  expect_equal(compare_sha1(shas, shas2), c("karate", "credentials"))
})