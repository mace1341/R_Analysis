# Tests for transform_template_data template function.

testthat::test_that("transform_template_data returns expected transformed tibble", {
  testthat::skip_if_not_installed("dplyr")
  testthat::skip_if_not_installed("tibble")
  testthat::skip_if_not_installed("rlang")

  source("R/function_template.R")

  input_df <- data.frame(
    id = 1:3,
    value = c(10, 20, 30)
  )

  result <- transform_template_data(input_df, value)

  testthat::expect_s3_class(result, "tbl_df")
  testthat::expect_equal(result$normalized_value, c(0, 0.5, 1))
  testthat::expect_named(result, c("id", "value", "normalized_value"))
})

testthat::test_that("transform_template_data validates bad inputs with clear errors", {
  testthat::skip_if_not_installed("dplyr")
  testthat::skip_if_not_installed("tibble")
  testthat::skip_if_not_installed("rlang")

  source("R/function_template.R")

  valid_df <- data.frame(value = c(1, 2, 3))

  testthat::expect_error(
    transform_template_data(list(a = 1), value),
    "must be a data.frame"
  )

  testthat::expect_error(
    transform_template_data(valid_df, missing_col),
    "is not present"
  )

  testthat::expect_error(
    transform_template_data(data.frame(value = c("a", "b")), value),
    "must be numeric"
  )

  testthat::expect_error(
    transform_template_data(valid_df, value, output_col = ""),
    "single, non-empty character string"
  )
})

testthat::test_that("transform_template_data handles zero-variance columns", {
  testthat::skip_if_not_installed("dplyr")
  testthat::skip_if_not_installed("tibble")
  testthat::skip_if_not_installed("rlang")

  source("R/function_template.R")

  input_df <- data.frame(value = c(5, 5, 5))

  result <- transform_template_data(input_df, value)

  testthat::expect_equal(result$normalized_value, c(0, 0, 0))
})
