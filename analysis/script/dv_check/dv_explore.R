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

derive_scan_dmets_long(
  tables_new$img,
  tables_new$ca_ind
) %>%
  derive_scan_dmets_first() %>%
  glimpse

derive_path_dmets_long(
  tables_new$path,
  tables_new$ca_ind,
  cohort_ca_types = c("Non Small Cell Lung Cancer", "Lung Cancer, NOS")
) %>%
  glimpse
derive_path_dmets_first() %>%
  glimpse
