#' Fetch and standardize S&P 500 constituents from Wikipedia
#'
#' @description
#' `fetch_sp500_companies()` retrieves the current S&P 500 constituents table
#' from Wikipedia, standardizes column names with `janitor::clean_names()`,
#' coerces `cik` to a zero-padded character field, and returns a tibble for
#' downstream analysis workflows.
#'
#' @param source_table Optional `data.frame`/tibble to transform instead of
#'   scraping from Wikipedia. Useful for testing or controlled pipelines.
#' @param url Wikipedia URL hosting the S&P 500 companies table.
#' @param cik_width Total width for zero-padding CIK values. Defaults to `10`.
#'
#' @return A tibble with cleaned names and a character `cik` column padded to
#'   `cik_width`.
#'
#' @examples
#' \dontrun{
#' sp500_tbl <- fetch_sp500_companies()
#' dplyr::glimpse(sp500_tbl)
#' }
#'
#' @export
fetch_sp500_companies <- function(
  source_table = NULL,
  url = "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies",
  cik_width = 10
) {
  if (!is.null(source_table) && !is.data.frame(source_table)) {
    stop("`source_table` must be NULL or a data.frame/tibble.", call. = FALSE)
  }

  if (!is.character(url) || length(url) != 1 || !nzchar(url)) {
    stop("`url` must be a single, non-empty character string.", call. = FALSE)
  }

  if (!is.numeric(cik_width) || length(cik_width) != 1 || is.na(cik_width) || cik_width < 1) {
    stop("`cik_width` must be a single positive numeric value.", call. = FALSE)
  }

  raw_table <- if (is.null(source_table)) {
    wiki_html <- rvest::read_html(url)
    rvest::html_element(wiki_html, "#constituents") |>
      rvest::html_table(convert = FALSE)
  } else {
    source_table
  }

  cleaned_table <- raw_table |>
    janitor::clean_names() |>
    tibble::as_tibble()

  if (!"cik" %in% names(cleaned_table)) {
    stop("Expected a `cik` column after cleaning names.", call. = FALSE)
  }

  cleaned_table |>
    dplyr::mutate(cik = stringr::str_pad(as.character(cik), width = cik_width, side = "left", pad = "0"))
}
