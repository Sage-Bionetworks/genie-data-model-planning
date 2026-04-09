pull_composite_id <- function(tables, table_name, ...) {
  tables |>
    purrr::pluck(table_name) |>
    dplyr::mutate(.id = paste(..., sep = "|")) |>
    dplyr::pull(.id)
}
