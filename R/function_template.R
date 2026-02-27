#' Transform Input Data with a Reusable Function Template
#'
#' @description
#' `transform_template_data()` demonstrates a reusable pattern for writing project
#' functions that are easy to test and extend. It validates inputs early,
#' performs a simple tidy transformation, and always returns a tibble.
#'
#' @param data A `data.frame` (or tibble) containing at least one numeric column.
#' @param value_col The unquoted or quoted name of the numeric column to transform.
#' @param output_col Name of the output column to create. Defaults to
#'   `"normalized_value"`.
#'
#' @return A tibble with all original columns plus `output_col`, where values are
#'   min-max scaled to the range `[0, 1]`.
#'
#' @details
#' Validation rules shown in this template:
#' \itemize{
#'   \item `data` must be a data frame.
#'   \item `value_col` must exist and be numeric.
#'   \item `output_col` must be a single, non-empty character string.
#' }
#'
#' If the selected column has zero variance, the function returns `0` for all
#' rows in `output_col` to avoid division-by-zero.
#'
#' @examples
#' sample_df <- data.frame(group = c("a", "b", "c"), value = c(10, 20, 30))
#' transform_template_data(sample_df, value)
#'
#' @export
transform_template_data <- function(data, value_col, output_col = "normalized_value") {
  # Validate `data` early so failures are immediate and informative.
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame or tibble.", call. = FALSE)
  }

  value_col_name <- rlang::as_name(rlang::ensym(value_col))

  # Confirm required input column exists.
  if (!value_col_name %in% names(data)) {
    stop(sprintf("`value_col` '%s' is not present in `data`.", value_col_name), call. = FALSE)
  }

  # Ensure numeric type because scaling below requires numeric input.
  if (!is.numeric(data[[value_col_name]])) {
    stop(sprintf("`value_col` '%s' must be numeric.", value_col_name), call. = FALSE)
  }

  # Validate output column name for predictable output shape.
  if (!is.character(output_col) || length(output_col) != 1 || !nzchar(output_col)) {
    stop("`output_col` must be a single, non-empty character string.", call. = FALSE)
  }

  min_value <- min(data[[value_col_name]], na.rm = TRUE)
  max_value <- max(data[[value_col_name]], na.rm = TRUE)

  # Handle constant vectors safely by returning 0 instead of dividing by zero.
  scaled_values <- if (isTRUE(all.equal(min_value, max_value))) {
    rep(0, nrow(data))
  } else {
    (data[[value_col_name]] - min_value) / (max_value - min_value)
  }

  data |>
    tibble::as_tibble() |>
    dplyr::mutate(!!output_col := scaled_values)
}
