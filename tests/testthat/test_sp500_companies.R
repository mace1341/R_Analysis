# Tests for fetch_sp500_companies function.

testthat::test_that("fetch_sp500_companies cleans headers and pads cik", {
  testthat::skip_if_not_installed("dplyr")
  testthat::skip_if_not_installed("janitor")
  testthat::skip_if_not_installed("stringr")
  testthat::skip_if_not_installed("tibble")

  source("R/sp500_companies.R")

  sample_input <- data.frame(
    Symbol = c("ABC", "XYZ"),
    CIK = c("123", "456789"),
    `Security Name` = c("A Co", "X Co")
  )

  result <- fetch_sp500_companies(source_table = sample_input)

  testthat::expect_s3_class(result, "tbl_df")
  testthat::expect_true(all(c("symbol", "cik", "security_name") %in% names(result)))
  testthat::expect_equal(result$cik, c("0000000123", "0000456789"))
})

testthat::test_that("fetch_sp500_companies validates inputs", {
  source("R/sp500_companies.R")

  testthat::expect_error(
    fetch_sp500_companies(source_table = 1),
    "must be NULL or a data.frame"
  )

  testthat::expect_error(
    fetch_sp500_companies(source_table = data.frame(a = 1), cik_width = 0),
    "single positive numeric value"
  )

  testthat::expect_error(
    fetch_sp500_companies(source_table = data.frame(a = 1)),
    "Expected a `cik` column"
  )
})
