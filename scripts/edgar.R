#!/usr/bin/env Rscript

# Edgar: retrieve the last 5 years of diluted EPS for all S&P 500 CIKs.

source("R/sp500_companies.R")

required_packages <- c("dplyr", "httr", "jsonlite", "purrr", "stringr", "tibble")
invisible(lapply(required_packages, require, character.only = TRUE))

get_edgar_diluted_eps <- function(cik, ticker, years = 5, user_agent = NULL) {
  cik_padded <- stringr::str_pad(as.character(cik), width = 10, side = "left", pad = "0")
  ua <- user_agent %||% sprintf("EdgarEPSScript/1.0 (%s)", Sys.info()[["user"]])

  endpoint <- sprintf("https://data.sec.gov/api/xbrl/companyfacts/CIK%s.json", cik_padded)

  response <- tryCatch(
    httr::GET(endpoint, httr::add_headers(`User-Agent` = ua)),
    error = function(e) NULL
  )

  if (is.null(response) || httr::http_error(response)) {
    return(tibble::tibble(cik = character(), ticker = character(), year = integer(), eps = numeric()))
  }

  payload <- tryCatch(
    jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"), simplifyDataFrame = TRUE),
    error = function(e) NULL
  )

  if (is.null(payload) ||
      is.null(payload$facts$`us-gaap`$EarningsPerShareDiluted$units)) {
    return(tibble::tibble(cik = character(), ticker = character(), year = integer(), eps = numeric()))
  }

  eps_units <- payload$facts$`us-gaap`$EarningsPerShareDiluted$units
  eps_values <- dplyr::bind_rows(lapply(eps_units, tibble::as_tibble), .id = "unit")

  if (nrow(eps_values) == 0) {
    return(tibble::tibble(cik = character(), ticker = character(), year = integer(), eps = numeric()))
  }

  annual_forms <- c("10-K", "10-K/A", "20-F", "20-F/A", "40-F", "40-F/A")

  eps_values |>
    dplyr::filter(!is.na(fy), form %in% annual_forms) |>
    dplyr::mutate(
      fy = suppressWarnings(as.integer(fy)),
      filed = as.Date(filed)
    ) |>
    dplyr::filter(!is.na(fy), !is.na(val)) |>
    dplyr::arrange(dplyr::desc(filed)) |>
    dplyr::group_by(fy) |>
    dplyr::slice_head(n = 1) |>
    dplyr::ungroup() |>
    dplyr::arrange(dplyr::desc(fy)) |>
    dplyr::slice_head(n = years) |>
    dplyr::transmute(
      cik = cik_padded,
      ticker = ticker,
      year = fy,
      eps = as.numeric(val)
    )
}

`%||%` <- function(a, b) if (!is.null(a) && length(a) == 1 && nzchar(a)) a else b

sp_500 <- fetch_sp500_companies() |>
  dplyr::select(cik, symbol) |>
  dplyr::rename(ticker = symbol)

max_ciks <- suppressWarnings(as.integer(Sys.getenv("MAX_CIKS", unset = NA_character_)))
if (is.na(max_ciks) || max_ciks < 1) {
  max_ciks <- nrow(sp_500)
}

sp_500_subset <- dplyr::slice_head(sp_500, n = max_ciks)

user_agent <- Sys.getenv("SEC_USER_AGENT", unset = sprintf("EdgarEPSScript/1.0 (%s)", Sys.info()[["user"]]))

financial_data <- purrr::map2_dfr(
  sp_500_subset$cik,
  sp_500_subset$ticker,
  function(cik, ticker) {
    Sys.sleep(0.12)
    get_edgar_diluted_eps(cik = cik, ticker = ticker, years = 5, user_agent = user_agent)
  }
)

print(financial_data)
