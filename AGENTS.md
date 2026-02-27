# Repository onboarding guide for coding agents

## R environment setup

1. Install R (version 4.3+ recommended) and ensure `Rscript` is on your `PATH`.
2. In the repository root, initialize dependencies (first run only):
   - `Rscript -e "renv::restore(prompt = FALSE)"`
3. For a clean setup on a new machine, run:
   - `Rscript scripts/check.R`

## Package installation instructions

- This repository uses **renv** for reproducible dependencies.
- Add new dependencies in scripts/functions, then snapshot:
  - `Rscript -e "renv::snapshot(prompt = FALSE)"`
- Restore dependencies from lockfile:
  - `Rscript -e "renv::restore(prompt = FALSE)"`
- If `renv` is not available, install it first:
  - `Rscript -e "install.packages('renv', repos = 'https://cloud.r-project.org')"`

## Running scripts

- Run from repository root so relative paths resolve correctly.
- Execute scripts with:
  - `Rscript scripts/<script_name>.R`
- Current entry points:
  - `scripts/check.R` (environment validation)
  - `scripts/example_analysis.R` (example workflow)

## Repository conventions (code organization)

- `R/`: shared, reusable functions only (no side effects at source time).
- `scripts/`: orchestration and analysis entry points.
- `data/`: local datasets, with optional `raw/` and `processed/` subfolders.
- `tests/`: unit/integration checks and test helpers.
- Keep script-specific helper code in `R/` when reused in more than one script.

## Naming conventions

### Functions

- Use `snake_case` for all function names (e.g., `fit_model`, `load_input_data`).
- Use verbs for action functions and nouns for pure transformers where sensible.
- Keep function files focused; one primary exported function per file is preferred.

### Scripts

- Use descriptive `snake_case.R` names.
- Prefix optional execution order for pipelines if needed, e.g.:
  - `01_load_data.R`
  - `02_train_model.R`
  - `03_report_results.R`
- Keep scripts executable end-to-end without manual interactive steps.
