#!/usr/bin/env Rscript

# Example analysis script for project onboarding.

source("R/hello_analysis.R")
source("R/sp500_companies.R")

required_packages <- c("dplyr", "janitor", "rvest", "stringr", "tibble")
invisible(lapply(required_packages, require, character.only = TRUE))

sp500_companies <- fetch_sp500_companies()

cat(hello_analysis("example_analysis", nrow(sp500_companies)), "\n")
cat("S&P 500 constituent data fetched and cleaned.\n")

sp500_summary <- sp500_companies |>
  dplyr::count(gics_sector, sort = TRUE)

print(utils::head(sp500_companies, 5))
print(sp500_summary)
