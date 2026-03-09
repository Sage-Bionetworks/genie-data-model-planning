# Layer 2 is the derived versions of the split data.
# This includes derived variables, variable typing, etc.
library(geniedv)
library(fs)
library(purrr)
purrr::walk(.x = fs::dir_ls(fs::path("R")), .f = source)

nested_splits <- readr::read_rds(
  path('data', 'dv', 'layer_1_split_tables', 'nested_splits.rds')
)

nested_splits <- nested_splits %>%
  select(site, nested_split_data) %>%
  unnest(nested_split_data)
