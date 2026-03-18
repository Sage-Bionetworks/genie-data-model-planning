# Load the new derived tables:
library(geniedv)
library(fs)
library(purrr)
purrr::walk(.x = fs::dir_ls(fs::path("R")), .f = source)

library(testthat)

restricted_tab_dir <- here('data', 'dv', 'layer_2_derived_tables')
tables_leg <- readr::read_rds(here(
  restricted_tab_dir,
  'restricted_tables_legacy.rds'
))
tables_new <- readr::read_rds(here(
  restricted_tab_dir,
  'restricted_tables_new.rds'
))

apply_column_scope <- function(tbl_list, scope_dir) {
  yaml_files <- fs::dir_ls(scope_dir, glob = "*.yaml")

  scope <- purrr::map(yaml_files, \(f) {
    cfg <- yaml::read_yaml(f)
    names(purrr::keep(cfg$columns, isTRUE))
  }) |>
    purrr::set_names(tools::file_path_sans_ext(basename(yaml_files)))

  purrr::imap(tbl_list, \(tbl, nm) {
    keep_cols <- scope[[nm]]
    if (is.null(keep_cols)) {
      cli::cli_warn(
        "No scope file found for table {.val {nm}} — keeping all columns."
      )
      return(tbl)
    }
    missing_cols <- setdiff(keep_cols, names(tbl))
    if (length(missing_cols) > 0) {
      cli::cli_warn(
        "Table {.val {nm}}: scoped columns not present and skipped: {.val {missing_cols}}"
      )
    }
    dplyr::select(tbl, dplyr::any_of(keep_cols))
  })
}

scope_dir <- here('analysis', 'script', 'dv_check', 'dv_check_scope')
tables_leg <- apply_column_scope(tables_leg, scope_dir)
tables_new <- apply_column_scope(tables_new, scope_dir)

test_that(
  expect_equal(tables_leg$pt$record_id, tables_new$pt$record_id)
)

waldo::compare(
  arrange(tables_leg$pt, record_id),
  arrange(tables_new$pt, record_id)
)
