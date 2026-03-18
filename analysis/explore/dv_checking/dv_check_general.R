# Load the new derived tables:
library(geniedv)
library(fs)
library(purrr)
purrr::walk(.x = fs::dir_ls(fs::path("R")), .f = source)

restricted_tab_dir <- here('data', 'dv', 'layer_2_derived_tables')
tables_leg <- readr::read_rds(here(
  restricted_tab_dir,
  'restricted_tables_legacy.rds'
))
tables_new <- readr::read_rds(here(
  restricted_tab_dir,
  'restricted_tables_new.rds'
))

apply_column_scope <- function(tables_leg, tables_new, scope_dir) {
  yaml_files <- fs::dir_ls(scope_dir, glob = "*.yaml")

  scope <- purrr::map(yaml_files, \(f) {
    cfg <- yaml::read_yaml(f)
    names(purrr::keep(cfg$columns, isTRUE))
  }) |>
    purrr::set_names(tools::file_path_sans_ext(basename(yaml_files)))

  select_cols <- function(tbl_list) {
    purrr::imap(tbl_list, \(tbl, nm) {
      keep_cols <- scope[[nm]]
      if (is.null(keep_cols)) {
        cli::cli_warn("No scope file found for table {.val {nm}} — keeping all columns.")
        return(tbl)
      }
      missing_cols <- setdiff(keep_cols, names(tbl))
      if (length(missing_cols) > 0) {
        cli::cli_warn("Table {.val {nm}}: scoped columns not present and skipped: {.val {missing_cols}}")
      }
      dplyr::select(tbl, dplyr::any_of(keep_cols))
    })
  }

  list(
    tables_leg = select_cols(tables_leg),
    tables_new = select_cols(tables_new)
  )
}

scope_dir <- here(restricted_tab_dir, 'dv_check_scope')
scoped <- apply_column_scope(tables_leg, tables_new, scope_dir)
tables_leg <- scoped$tables_leg
tables_new  <- scoped$tables_new
