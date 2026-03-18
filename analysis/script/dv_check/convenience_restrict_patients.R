library(geniedv)
library(fs)
library(purrr)
purrr::walk(.x = fs::dir_ls(fs::path("R")), .f = source)

tables_new <- readr::read_rds(here(path(
  'data',
  'dv',
  'layer_2_derived_tables',
  'table_list.rds'
)))
