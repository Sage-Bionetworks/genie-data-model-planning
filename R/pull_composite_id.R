pull_composite_id <- function(tables, table_name, ...) {
  tables |>
    purrr::pluck(table_name) |>
    tidyr::unite(".id", ..., sep = "|", remove = FALSE) |>
    dplyr::pull(.id)
}
