library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

curated_path <- here('data-raw', 'bpc', 'step1-curated', 'NSCLC2')

dat_ex <- readr::read_csv(
  dir_ls(here(curated_path, "DFCI"))
)

dat_dict <- readr::read_rds(
  here('data', 'bpc', 'step1-curated', 'aligned_data_dictionary.rds')
)


library(pointblank)

data(small_table)

small_table %>%
  col_vals_lt(a, value = 10) %>%
  col_vals_between(d, left = 0, right = 5000) %>%
  col_vals_in_set(f, set = c('low', 'mid', 'high'))


agent <- small_table %>%
  create_agent() %>% 
  col_vals_lt(a, value = 10) %>%
  col_vals_between(d, left = 0, right = 5000) %>% 
  col_vals_in_set(f, set = c("low", "mid", "high")) %>%
  col_vals_regex(b, regex = "^[0-9]-[a-z]{3}-[0-9]{3}$") 

agent %>%
  interrogate()


al <- action_levels(warn_at = 2, stop_at = 4)

small_table %>%
  col_vals_lt(a, value = 7, actions = al)

# one that intentionally fails:
# small_table %>%
#   create_agent(actions = al) %>% 
#   col_vals_lt(a, value = 7) %>%
#   interrogate()

# I think the best way to figure out what workflow will suit me is programming some actual checks in:
req_cols <- dat_dict %>%
  filter(required) %>%
  pull(field_name)
dat_ex %>%
  
