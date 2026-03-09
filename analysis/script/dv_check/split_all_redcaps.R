library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

dd_path <- path('data', 'dv', 'aligned_dd', 'dd_nested.rds')

dd_nested <- readr::read_rds(dd_path)

# Example of doing one at at time:
redcap_splitter(
  filter(dd_nested, site %in% "DFCI")$cur_path,
  filter(dd_nested, site %in% "DFCI")$aligned_dd[[1]]
)

# We'll do them all:
cur_dat_mani <- dd_nested %>%
  mutate(
    nested_split_data = purrr::map2(
      .x = cur_path,
      .y = aligned_dd,
      .f = \(x, y) redcap_splitter(redcap_data_path = x, dict = y)
    )
  )

out_dir <- here('data', 'dv', 'layer_1_split_tables')

readr::write_rds(
  cur_dat_mani,
  here(out_dir, 'nested_splits.rds')
)

multisite_tables <- cur_dat_mani %>%
  # keeping site temporarily just to have unique rows.
  select(site, nested_split_data) %>%
  unnest(nested_split_data) %>%
  select(site, form_in_extract, tab)

# This fails:
multisite_tables <- multisite_tables %>%
  group_by(form_in_extract) %>%
  summarize(multitab = list(bind_rows(tab)))

multisite_tables
