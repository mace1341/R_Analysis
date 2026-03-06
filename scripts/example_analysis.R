#!/usr/bin/env Rscript

# Example analysis script for project onboarding.

source("R/hello_analysis.R")

required_packages <- c("stats")
invisible(lapply(required_packages, require, character.only = TRUE))

set.seed(42)
values <- rnorm(100)
summary_stats <- summary(values)

cat(hello_analysis("example_analysis", length(values)), "\n")
cat("Example analysis completed.\n")
print(summary_stats)
