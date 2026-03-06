# Tests for hello_analysis starter function.

testthat::test_that("hello_analysis returns expected message", {
  source("R/hello_analysis.R")

  result <- hello_analysis("demo_project", 25)

  testthat::expect_type(result, "character")
  testthat::expect_length(result, 1)
  testthat::expect_equal(result, "Hello from demo_project! Processed 25 rows.")
})

testthat::test_that("hello_analysis validates inputs", {
  source("R/hello_analysis.R")

  testthat::expect_error(
    hello_analysis("", 1),
    "single, non-empty character string"
  )

  testthat::expect_error(
    hello_analysis("ok", -1),
    "single non-negative numeric value"
  )

  testthat::expect_error(
    hello_analysis("ok", NA_real_),
    "single non-negative numeric value"
  )
})
