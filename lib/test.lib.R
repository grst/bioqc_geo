library(testthat)

source("./lib.R")

test_that("Test chooseSignature", {
  df = data.frame(x=c(1,4,3,2))
  rownames(df) = c("a", "b", "c", "d")
  sig.list=list("a", "b", "c")
  expect_equal(chooseSignature(df, sig.list), "b")
})