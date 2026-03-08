#!/usr/bin/env Rscript

# Edgar: retrieve 5 years of quarterly diluted EPS and trailing annual totals for S&P 500 CIKs.

source("R/sp500_companies.R")

required_packages <- c("dplyr", "httr", "jsonlite", "purrr", "stringr", "tibble")
invisible(lapply(required_packages, require, character.only = TRUE))

`%||%` <- function(a, b) if (!is.null(a) && length(a) == 1 && nzchar(a)) a else b

get_edgar_quarterly_diluted_eps <- function(cik, ticker, years = 5, user_agent = NULL) {
  cik_padded <- stringr::str_pad(as.character(cik), width = 10, side = "left", pad = "0")
  ua <- user_agent %||% sprintf("EdgarEPSScript/1.0 (%s)", Sys.info()[["user"]])

  endpoint <- sprintf("https://data.sec.gov/api/xbrl/companyfacts/CIK%s.json", cik_padded)

  response <- tryCatch(
    httr::GET(endpoint, httr::add_headers(`User-Agent` = ua)),
    error = function(e) NULL
  )

  empty_result <- tibble::tibble(
    CIK = character(),
    Ticker = character(),
    quarter = character(),
    year = integer(),
    quarterly_eps = numeric(),
    trailing_annual_eps = numeric()
  )

  if (is.null(response) || httr::http_error(response)) {
    return(empty_result)
  }

  payload <- tryCatch(
    jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"), simplifyDataFrame = TRUE),
    error = function(e) NULL
  )

  if (is.null(payload) ||
      is.null(payload$facts$`us-gaap`$EarningsPerShareDiluted$units)) {
    return(empty_result)
  }

  eps_units <- payload$facts$`us-gaap`$EarningsPerShareDiluted$units
  eps_values <- dplyr::bind_rows(lapply(eps_units, tibble::as_tibble), .id = "unit")

  if (nrow(eps_values) == 0) {
    return(empty_result)
  }

  quarterly_forms <- c("10-Q", "10-Q/A", "10-QT", "10-QT/A")

  quarter_map <- c(Q1 = 1L, Q2 = 2L, Q3 = 3L, Q4 = 4L)

  quarterly_data <- eps_values |>
    dplyr::filter(!is.na(fy), !is.na(fp), form %in% quarterly_forms, fp %in% names(quarter_map)) |>
    dplyr::mutate(
      fy = suppressWarnings(as.integer(fy)),
      quarter = as.character(fp),
      quarter_num = unname(quarter_map[quarter]),
      filed = as.Date(filed),
      quarterly_eps = as.numeric(val)
    ) |>
    dplyr::filter(!is.na(fy), !is.na(quarter_num), !is.na(quarterly_eps)) |>
    dplyr::arrange(dplyr::desc(filed)) |>
    dplyr::group_by(fy, quarter) |>
    dplyr::slice_head(n = 1) |>
    dplyr::ungroup()

  if (nrow(quarterly_data) == 0) {
    return(empty_result)
  }

  latest_years <- quarterly_data |>
    dplyr::distinct(fy) |>
    dplyr::arrange(dplyr::desc(fy)) |>
    dplyr::slice_head(n = years) |>
    dplyr::pull(fy)

  quarterly_data |>
    dplyr::filter(fy %in% latest_years) |>
    dplyr::arrange(fy, quarter_num) |>
    dplyr::mutate(
      trailing_annual_eps =
        quarterly_eps +
        dplyr::lag(quarterly_eps, 1) +
        dplyr::lag(quarterly_eps, 2) +
        dplyr::lag(quarterly_eps, 3)
    ) |>
    dplyr::transmute(
      CIK = cik_padded,
      Ticker = ticker,
      quarter = quarter,
      year = fy,
      quarterly_eps = quarterly_eps,
      trailing_annual_eps = trailing_annual_eps
    )
}

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
    get_edgar_quarterly_diluted_eps(cik = cik, ticker = ticker, years = 5, user_agent = user_agent)
  }
)

print(financial_data)
