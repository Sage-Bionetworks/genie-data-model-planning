# Layer 2 is the derived versions of the split data.
# This includes derived variables, variable typing, etc.
library(geniedv)
library(fs)
library(purrr)
purrr::walk(.x = fs::dir_ls(fs::path("R")), .f = source)

out_dir_dv <- path('data', 'dv', 'layer_2_derived_tables')
fs::dir_create(out_dir_dv)

nested_splits <- readr::read_rds(
  path('data', 'dv', 'layer_1_split_tables', 'nested_splits.rds')
)

nested_splits <- nested_splits %>%
  select(site, nested_split_data) %>%
  unnest(nested_split_data)

# Seems like there might be a nicer way to write this with switch()
dv_code_dispatch <- function(tab, dd_sub, form_name) {
  if (form_name %in% "patient") {
    derive_pt(tab, dd_sub)
  } else if (form_name %in% "cancer_diagnosis") {
    derive_ca_dx(tab, dd_sub)
  } else if (form_name %in% "ca_directed_drugs") {
    derive_reg(tab, dd_sub)
  } else if (form_name %in% "ca_directed_radtx") {
    derive_rad(tab, dd_sub)
  } else if (form_name %in% "prissmm_pathology") {
    derive_path(tab, dd_sub)
  } else if (form_name %in% "prissmm_imaging") {
    derive_img(tab, dd_sub)
  } else if (form_name %in% "prissmm_med_onc_assessment") {
    derive_med_onc(tab, dd_sub)
  } else if (form_name %in% "cancer_panel_test") {
    derive_cpt(tab, dd_sub)
  } else {
    NULL
  }
}

# Example of one use:
# dv_code_dispatch(
#   tab = nested_splits$tab[[2]],
#   dd_sub = nested_splits$dat_dict_sub[[2]],
#   form_name = nested_splits$form_in_extract[[2]]
# )

# Doing them all:
nested_splits <- nested_splits %>%
  mutate(
    dv_tab = purrr::pmap(
      .l = list(tab = tab, dd_sub = dat_dict_sub, form_name = form_in_extract),
      .f = dv_code_dispatch
    )
  )

readr::write_rds(nested_splits, path(out_dir_dv, 'nested_dv.rds'))

multisite_tables <- nested_splits %>%
  # keeping site temporarily just to have unique rows.
  select(site, form_in_extract, dv_tab) %>%
  group_by(form_in_extract) %>%
  summarize(dv_tab = list(bind_rows(dv_tab)))

ca_split <- multisite_tables %>%
  filter(form_in_extract %in% 'cancer_diagnosis') %>%
  pull(dv_tab) %>%
  .[[1]] %>%
  split_ca_all(.)

multisite_tables %<>%
  filter(!(form_in_extract %in% 'cancer_diagnosis')) %>%
  add_row(form_in_extract = 'ca_ind', dv_tab = list(ca_split$ca_ind)) %>%
  add_row(form_in_extract = 'ca_non_ind', dv_tab = list(ca_split$ca_non_ind))

multisite_tables %<>%
  filter(purrr::map_dbl(dv_tab, nrow) > 0) %>%
  mutate(name = dat_name_to_short(form_in_extract)) %>%
  arrange(name)

multisite_tables %<>% select(name, dv_tab)

multisite_list <- pull(multisite_tables, dv_tab)
names(multisite_list) <- pull(multisite_tables, name)

propagate_ca_seq <- function(lst) {
  ca_seq_lookup <- bind_rows(
    lst[["ca_ind"]],
    lst[["ca_non_ind"]]
  ) |>
    select(record_id, redcap_ca_seq, ca_seq)

  ca_tables <- c("ca_ind", "ca_non_ind")
  purrr::imap(lst, \(tab, nm) {
    if (nm %in% ca_tables) {
      return(tab)
    }
    if (!("redcap_ca_seq" %in% names(tab))) {
      return(tab)
    }
    tab |>
      dplyr::left_join(ca_seq_lookup, by = c("record_id", "redcap_ca_seq"))
  })
}

multisite_list <- propagate_ca_seq(multisite_list)

readr::write_rds(
  multisite_list,
  here(out_dir_dv, 'table_list.rds')
)
