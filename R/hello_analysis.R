#' Create a friendly analysis summary message
#'
#' @description
#' `hello_analysis()` returns a simple, deterministic message that includes a
#' project label and a row count. This function is intentionally lightweight and
#' is meant as a starter example for wiring reusable functions into scripts.
#'
#' @param project_name A single non-empty character string used in the greeting.
#' @param n_rows A single non-negative numeric value representing number of rows
#'   analyzed.
#'
#' @return A length-1 character vector with a formatted summary message.
#'
#' @examples
#' hello_analysis("demo", 100)
#'
#' @export
hello_analysis <- function(project_name = "example_analysis", n_rows = 0) {
  if (!is.character(project_name) || length(project_name) != 1 || !nzchar(project_name)) {
    stop("`project_name` must be a single, non-empty character string.", call. = FALSE)
  }

  if (!is.numeric(n_rows) || length(n_rows) != 1 || is.na(n_rows) || n_rows < 0) {
    stop("`n_rows` must be a single non-negative numeric value.", call. = FALSE)
  }

  sprintf("Hello from %s! Processed %s rows.", project_name, format(n_rows, trim = TRUE))
}
