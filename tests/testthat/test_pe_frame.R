# Tests for build_pe_and_price_frames.

testthat::test_that("build_pe_and_price_frames computes forward-filled EPS and PE ratio", {
  testthat::skip_if_not_installed("dplyr")
  testthat::skip_if_not_installed("tibble")

  source("R/pe_frame.R")

  financial_data <- tibble::tibble(
    cik = "0000000001",
    ticker = "AAA",
    year = c(2024, 2024),
    quarter = c("Q1", "Q2"),
    trailing_annual_eps = c(2, 0)
  )

  sp500_companies <- tibble::tibble(
    cik = "0000000001",
    symbol = "AAA",
    security = "AAA Corp",
    gics_sector = "Tech",
    gics_sub_industry = "Software"
  )

  price_data <- tibble::tibble(
    ticker = rep("AAA", 35),
    date = seq.Date(as.Date("2024-03-31"), by = "day", length.out = 35),
    price = seq(100, 134)
  )

  out <- build_pe_and_price_frames(
    financial_data = financial_data,
    sp500_companies = sp500_companies,
    price_data = price_data
  )

  testthat::expect_true(all(c("cik", "ticker", "date", "price", "ma_30d_price") %in% names(out$price)))
  testthat::expect_true(all(c("twelve_month_eps", "pe_ratio", "company_name", "category_level_1", "category_level_2") %in% names(out$pe)))

  # First EPS becomes available on Q1 date and is forward filled.
  eps_on_apr <- out$pe |>
    dplyr::filter(date == as.Date("2024-04-15")) |>
    dplyr::pull(twelve_month_eps)
  testthat::expect_equal(eps_on_apr, 2)

  # Q2 EPS is zero, so pe_ratio should be NA from that date onward.
  pe_after_q2 <- out$pe |>
    dplyr::filter(date >= as.Date("2024-06-30")) |>
    dplyr::pull(pe_ratio)
  testthat::expect_true(all(is.na(pe_after_q2)))
})
