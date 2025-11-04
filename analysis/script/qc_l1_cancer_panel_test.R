library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

site_to_qc <- "DFCI"
current_form <- 'cancer_panel_test'

nested_dat <- readr::read_rds(
  here('data', 'qc', site_to_qc, 'layer_1_datasets', 'nested_l1.rds')
)

dict_sub <- nested_dat %>%
  filter(form_in_extract %in% current_form) %>%
  pull(dat_dict_sub) %>%
  .[[1]]

dat <- nested_dat %>%
  filter(form_in_extract %in% current_form) %>%
  pull(tab) %>%
  .[[1]]

ag <- agent_start(
  dat = dat,
  table_name = current_form
)

ag <- add_valid_value_checks_to_agent(
  data_dict = dict_sub,
  ptblank_agent = ag
)

# Add other checks as needed here.

ag_intel <- ag %>% pointblank::interrogate(progress = F)

ag_sum <- make_agent_table_row(
  dat_dict = dat_dict,
  interrogated_agent = ag_intel,
  qc_layer = 1,
  site_to_qc = site_to_qc
)

readr::write_rds(
  ag_sum,
  here(
    'data',
    'qc',
    site_to_qc,
    'qc_results',
    paste0('l1_', current_form, '.rds')
  )
)
