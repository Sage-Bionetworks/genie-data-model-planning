# Load the new derived tables:
library(geniedv)
library(fs)
library(purrr)
purrr::walk(.x = fs::dir_ls(fs::path("R")), .f = source)

library(testthat)

restricted_tab_dir <- here('data', 'dv', 'layer_2_derived_tables')
tables_leg <- readr::read_rds(here(
  restricted_tab_dir,
  'comparable_tables_legacy.rds'
))
tables_new <- readr::read_rds(here(
  restricted_tab_dir,
  'comparable_tables_new.rds'
))


scope_dir <- here('analysis', 'script', 'dv_check', 'dv_check_scope')
tables_leg <- apply_column_scope(tables_leg, scope_dir)
tables_new <- apply_column_scope(tables_new, scope_dir)

test_that(
  "Same set of record_id's in pt table",
  expect_setequal(tables_leg$pt$record_id, tables_new$pt$record_id)
)

cli::cli_inform(
  "Columns being checked in pt: {.code tables_leg$pt}: {.val {names(tables_leg$pt)}}"
)

waldo::compare(
  arrange(tables_leg$pt, record_id),
  arrange(tables_new$pt, record_id)
)

test_that(
  "Same set of record_id|ca_seq values in ca_ind table",
  expect_setequal(
    pull_composite_id(tables_leg, "ca_ind", record_id, ca_seq),
    pull_composite_id(tables_new, "ca_ind", record_id, ca_seq)
  )
)

cli::cli_inform(
  "Columns being checked in ca_ind: {.code tables_leg$ca_ind}: {.val {names(tables_leg$ca_ind)}}"
)

waldo::compare(
  arrange(tables_leg$ca_ind, record_id, ca_seq),
  arrange(tables_new$ca_ind, record_id, ca_seq),
  tolerance = 1e-6
)

test_that(
  "Same set of record_id|ca_seq values in ca_ind table",
  expect_setequal(
    pull_composite_id(tables_leg, "reg", record_id, ca_seq, regimen_number),
    pull_composite_id(tables_new, "reg", record_id, ca_seq, regimen_number)
  )
)

cli::cli_inform(
  "Columns being checked in reg: {.code tables_leg$reg}: {.val {names(tables_leg$reg)}}"
)

waldo::compare(
  arrange(tables_leg$reg, record_id, ca_seq, regimen_number),
  arrange(tables_new$reg, record_id, ca_seq, regimen_number),
  tolerance = 1e-6
)
