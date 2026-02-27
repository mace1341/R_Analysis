#!/usr/bin/env Rscript

required_packages <- c("renv")

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("Installing missing package: %s", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  } else {
    message(sprintf("Package already installed: %s", pkg))
  }
}

invisible(lapply(required_packages, install_if_missing))

suppressPackageStartupMessages({
  library(renv)
})

message(sprintf("R version: %s", getRversion()))
message(sprintf("renv version: %s", as.character(packageVersion("renv"))))
message("Environment validation successful.")
