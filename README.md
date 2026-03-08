# R Analysis

This repository is a starter template for reproducible R analysis workflows.

## Project layout

- `R/` reusable R functions and project modules.
- `scripts/` executable scripts (entry points for analyses and checks).
- `data/` local data files (keep raw/source data organized in subfolders as needed).
- `tests/` tests and validation scripts.

## Quick start

1. Install R (>= 4.3 recommended).
2. Run `Rscript scripts/check.R` to validate your environment.
3. Run `Rscript scripts/example_analysis.R` to fetch and summarize S&P 500 constituents.
4. Use reusable functions in `R/` (for example, `hello_analysis()` and `fetch_sp500_companies()`) for downstream workflows.

5. Build daily price and P/E analytics frames from SEC EPS + Yahoo Finance data with `scripts/build_pe_frame.R` (requires a `financial_data` object in memory and R package `quantmod`).

## S&P 500 data workflow

The repository now includes `fetch_sp500_companies()` in `R/sp500_companies.R`.
This function:

- Reads the S&P 500 constituents table from Wikipedia.
- Cleans column headers using `janitor::clean_names()`.
- Returns a tibble for predictable downstream usage.
- Converts `cik` into a zero-padded character field (10 digits by default).

Example usage:

```r
source("R/sp500_companies.R")

sp500_companies <- fetch_sp500_companies()
str(sp500_companies)
```

## Reproducibility

Dependencies are managed with `renv`. Use `renv::restore()` to recreate the project library from `renv.lock`.

## Creating New Functions

Use `R/function_template.R` as the baseline pattern when adding reusable functions:

- Add roxygen2 headers (`@description`, `@param`, `@return`, `@examples`) so documentation can be generated consistently.
- Validate arguments up front with clear, actionable error messages.
- Keep transformation logic tidyverse-friendly and return a tibble for predictable downstream usage.
- Add tests in `tests/testthat/` that verify expected output, input validation, and edge cases.
