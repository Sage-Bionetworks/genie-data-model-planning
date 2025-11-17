# Layer 2 is the derived versions of the split data.
# This includes derived variables, variable typing, etc.
purrr::walk(.x = fs::dir_ls(here::here("R")), .f = source)

site_to_qc <- "DFCI"

nested_dat <- readr::read_rds(
  here('data', 'qc', site_to_qc, 'layer_1_datasets', 'nested_l1.rds')
)


test_dd <- nested_dat %>%
  filter(form_in_extract %in% 'cancer_diagnosis') %>%
  pull(dat_dict_sub) %>%
  .[[1]]

test_tab <- nested_dat %>%
  filter(form_in_extract %in% 'cancer_diagnosis') %>%
  pull(tab) %>%
  .[[1]]

# demo of this function while it's new and shiny:
convert_dat_num2val(
  dict = test_dd,
  dat = test_tab,
  remove_names = F
) %>%
  select(redcap_ca_index, ca_type, ca_bca_er, ca_first_dmets1, ca_qamajor___4)

common_data_derivation_operations <- function(
  dat,
  dict
) {
  
  
}
  test_tab %>%
    mutate(
      redcap_ca_index_meaning = redcap_numbers_to_meaning(
        vec = redcap_ca_index,
        key_val_pairs = kvp_test
      )
    ) %>%
    select(contains('redcap_ca_index'))
}


derive_ca_dx <- function(
  dat_dict_sub,
  tab
) {
  tab <- convert_dat_num2val(
    dict = dat_dict_sub,
    dat = tab
  )
}

derive_ca_dx %>% glimpse
