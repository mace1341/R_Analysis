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
3. Run `Rscript scripts/example_analysis.R` to execute the example analysis.

## Reproducibility

Dependencies are managed with `renv`. Use `renv::restore()` to recreate the project library from `renv.lock`.
