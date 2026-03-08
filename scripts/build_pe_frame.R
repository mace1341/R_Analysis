#!/usr/bin/env Rscript

source("R/sp500_companies.R")
source("R/pe_frame.R")

required_packages <- c("dplyr", "tibble")
invisible(lapply(required_packages, require, character.only = TRUE))

if (!exists("financial_data", inherits = FALSE)) {
  stop("`financial_data` is not defined. Create/load it first (for example via `scripts/edgar.R`) and then source this script.", call. = FALSE)
}

sp500_tbl <- fetch_sp500_companies()

frames <- build_pe_and_price_frames(
  financial_data = financial_data,
  sp500_companies = sp500_tbl,
  years = 5
)

price <- frames$price
pe <- frames$pe

cat("Built `price` and `pe` frames.\n")
cat(sprintf("price rows: %d\n", nrow(price)))
cat(sprintf("pe rows: %d\n", nrow(pe)))
print(utils::head(pe, 10))
