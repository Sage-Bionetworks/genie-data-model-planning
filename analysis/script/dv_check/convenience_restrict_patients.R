library(geniedv)
library(fs)
library(purrr)
purrr::walk(.x = fs::dir_ls(fs::path("R")), .f = source)

multisite_tables <- readr::read_rds(here(path(
  'data',
  'dv',
  'layer_2_derived_tables',
  'multisite_tables.rds'
)))
