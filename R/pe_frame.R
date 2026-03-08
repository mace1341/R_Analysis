#' Build Daily Price and P/E Frames from SEC EPS and Yahoo Finance Prices
#'
#' @description
#' Builds two analysis frames:
#' - `price`: daily adjusted prices and 30-day moving average by ticker/cik.
#' - `pe`: daily 30-day average price merged with forward-filled twelve-month EPS,
#'   plus sector metadata and computed P/E ratio.
#'
#' Price history is retrieved from Yahoo Finance via `quantmod::getSymbols()`.
#'
#' @param financial_data Data frame containing at least `cik`, `ticker`, `year`,
#'   `quarter`, and trailing 12-month EPS (`trailing_annual_eps` or
#'   `twelve_month_eps`). Column names are matched case-insensitively.
#' @param sp500_companies Optional S&P metadata table with `cik`, `symbol`, name,
#'   and category columns. If `NULL`, this is fetched via `fetch_sp500_companies()`.
#' @param years Number of years of daily prices to retrieve. Default is `5`.
#' @param price_data Optional pre-built daily price frame with `ticker`, `date`,
#'   and `price` columns; if supplied, Yahoo download is skipped.
#'
#' @return A named list with elements `price` and `pe`.
#' @examples
#' \dontrun{
#' source("R/sp500_companies.R")
#' source("R/pe_frame.R")
#' out <- build_pe_and_price_frames(financial_data)
#' str(out$price)
#' str(out$pe)
#' }
build_pe_and_price_frames <- function(financial_data,
                                      sp500_companies = NULL,
                                      years = 5,
                                      price_data = NULL) {
  if (!is.data.frame(financial_data)) {
    stop("`financial_data` must be a data.frame.", call. = FALSE)
  }

  if (!is.numeric(years) || length(years) != 1 || is.na(years) || years <= 0) {
    stop("`years` must be a single positive numeric value.", call. = FALSE)
  }

  names(financial_data) <- tolower(names(financial_data))

  required_cols <- c("cik", "ticker", "year", "quarter")
  missing_required <- setdiff(required_cols, names(financial_data))
  if (length(missing_required) > 0) {
    stop(sprintf("`financial_data` is missing required columns: %s", paste(missing_required, collapse = ", ")), call. = FALSE)
  }

  eps_col <- if ("twelve_month_eps" %in% names(financial_data)) {
    "twelve_month_eps"
  } else if ("trailing_annual_eps" %in% names(financial_data)) {
    "trailing_annual_eps"
  } else {
    stop("`financial_data` must include `twelve_month_eps` or `trailing_annual_eps`.", call. = FALSE)
  }

  fin <- dplyr::transmute(
    financial_data,
    cik = as.character(cik),
    ticker = as.character(ticker),
    year = suppressWarnings(as.integer(year)),
    quarter = as.character(quarter),
    twelve_month_eps = as.numeric(.data[[eps_col]])
  )

  if (is.null(sp500_companies)) {
    if (!exists("fetch_sp500_companies", mode = "function")) {
      stop("`fetch_sp500_companies()` not found. Source `R/sp500_companies.R` or pass `sp500_companies`.", call. = FALSE)
    }
    sp500_companies <- fetch_sp500_companies()
  }

  names(sp500_companies) <- tolower(names(sp500_companies))

  pick_first_col <- function(df, candidates) {
    found <- intersect(candidates, names(df))
    if (length(found) == 0) {
      return(rep(NA_character_, nrow(df)))
    }
    as.character(df[[found[1]]])
  }

  company_lookup <- tibble::tibble(
    cik = as.character(sp500_companies$cik),
    ticker = pick_first_col(sp500_companies, c("symbol", "ticker")),
    company_name = pick_first_col(sp500_companies, c("security", "security_name", "name")),
    category_level_1 = pick_first_col(sp500_companies, c("gics_sector", "sector")),
    category_level_2 = pick_first_col(sp500_companies, c("gics_sub_industry", "sub_industry"))
  )

  quarter_end_date <- function(year, quarter) {
    month_day <- dplyr::case_when(
      quarter == "Q1" ~ "03-31",
      quarter == "Q2" ~ "06-30",
      quarter == "Q3" ~ "09-30",
      quarter == "Q4" ~ "12-31",
      TRUE ~ NA_character_
    )
    as.Date(ifelse(is.na(year) | is.na(month_day), NA_character_, sprintf("%04d-%s", year, month_day)))
  }

  fin_eps <- fin |>
    dplyr::mutate(eps_date = quarter_end_date(year, quarter)) |>
    dplyr::filter(!is.na(eps_date)) |>
    dplyr::distinct(cik, ticker, eps_date, .keep_all = TRUE) |>
    dplyr::arrange(cik, ticker, eps_date)

  tickers <- fin_eps |>
    dplyr::distinct(ticker) |>
    dplyr::filter(!is.na(ticker), nzchar(ticker)) |>
    dplyr::pull(ticker)

  if (length(tickers) == 0) {
    stop("No valid tickers found in `financial_data`.", call. = FALSE)
  }

  if (is.null(price_data)) {
    end_date <- Sys.Date()
    start_date <- end_date - as.integer(round(years * 365.25))
    price_data <- fetch_yahoo_adjusted_prices(
      tickers = tickers,
      start_date = start_date,
      end_date = end_date
    )
  }

  names(price_data) <- tolower(names(price_data))
  needed_price_cols <- c("ticker", "date", "price")
  if (!all(needed_price_cols %in% names(price_data))) {
    stop("`price_data` must include `ticker`, `date`, and `price` columns.", call. = FALSE)
  }

  fill_forward <- function(x) {
    idx <- cumsum(!is.na(x))
    out <- x
    positive <- idx > 0
    out[positive] <- x[match(idx[positive], idx)]
    out
  }

  price <- price_data |>
    dplyr::transmute(
      ticker = as.character(ticker),
      date = as.Date(date),
      price = as.numeric(price)
    ) |>
    dplyr::filter(!is.na(date), !is.na(price)) |>
    dplyr::arrange(ticker, date) |>
    dplyr::left_join(fin_eps |> dplyr::distinct(cik, ticker), by = "ticker") |>
    dplyr::group_by(cik, ticker) |>
    dplyr::mutate(
      ma_30d_price = as.numeric(stats::filter(price, rep(1 / 30, 30), sides = 1))
    ) |>
    dplyr::ungroup() |>
    dplyr::select(cik, ticker, date, price, ma_30d_price)

  pe <- price |>
    dplyr::left_join(
      fin_eps |> dplyr::select(cik, ticker, eps_date, twelve_month_eps),
      by = c("cik", "ticker", "date" = "eps_date")
    ) |>
    dplyr::arrange(cik, ticker, date) |>
    dplyr::group_by(cik, ticker) |>
    dplyr::mutate(twelve_month_eps = fill_forward(twelve_month_eps)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      pe_ratio = dplyr::if_else(
        is.na(twelve_month_eps) | twelve_month_eps == 0,
        NA_real_,
        ma_30d_price / twelve_month_eps
      ),
      pe_ratio_status = dplyr::if_else(
        is.na(twelve_month_eps) | twelve_month_eps == 0,
        "eps_missing_or_zero",
        "ok"
      )
    ) |>
    dplyr::left_join(company_lookup, by = c("cik", "ticker"))

  list(price = price, pe = pe)
}

fetch_yahoo_adjusted_prices <- function(tickers, start_date, end_date) {
  if (length(tickers) == 0) {
    return(tibble::tibble(ticker = character(), date = as.Date(character()), price = numeric()))
  }

  tickers <- unique(as.character(tickers))
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)

  if (!requireNamespace("quantmod", quietly = TRUE)) {
    stop("Package `quantmod` is required to download Yahoo price data.", call. = FALSE)
  }

  pull_one_ticker <- function(ticker) {
    symbol_xts <- tryCatch(
      quantmod::getSymbols(
        Symbols = ticker,
        src = "yahoo",
        from = start_date,
        to = end_date,
        auto.assign = FALSE,
        warnings = FALSE
      ),
      error = function(e) NULL
    )

    if (is.null(symbol_xts)) {
      return(tibble::tibble(ticker = character(), date = as.Date(character()), price = numeric()))
    }

    adj_series <- tryCatch(quantmod::Ad(symbol_xts), error = function(e) NULL)
    if (is.null(adj_series)) {
      return(tibble::tibble(ticker = character(), date = as.Date(character()), price = numeric()))
    }

    tibble::tibble(
      ticker = ticker,
      date = as.Date(zoo::index(adj_series)),
      price = as.numeric(adj_series[, 1])
    ) |>
      dplyr::filter(!is.na(price))
  }

  dplyr::bind_rows(lapply(tickers, pull_one_ticker))
}
