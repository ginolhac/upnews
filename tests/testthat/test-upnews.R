context("basic functionality")
# based on https://github.com/hrbrmstr/dtupdate/tree/master/tests/testthat
test_that("we can run the function and get back a dat frame", {
  expect_that(upnews(), is_a("data.frame"))
})