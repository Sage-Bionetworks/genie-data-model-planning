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

readr::write_rds(
  multisite_tables,
  here(out_dir_dv, 'multisite_tables.rds')
)

# Can easily add stuff to this as needed later on.
dat_name_to_short <- function(dat_name_long, factorize = T) {
  # go by the data guide order for my sanity:
  fact_order <- c(
    'pt',
    'ca_all',
    'reg',
    'rad',
    'path',
    'img',
    'med_onc',
    'cpt',
    'mark'
  )

  rtn <- case_when(
    dat_name_long %in% c('ca_all', 'cancer_diagnosis') ~ 'ca_all',
    dat_name_long %in% c('reg', 'ca_directed_drugs') ~ 'reg',
    dat_name_long %in% 'ca_directed_radtx' ~ 'rad',
    dat_name_long %in% 'cancer_panel_test' ~ 'cpt',
    dat_name_long %in% 'patient' ~ 'pt',
    dat_name_long %in% 'prissmm_imaging' ~ 'img',
    dat_name_long %in% 'prissmm_med_onc_assessment' ~ 'med_onc',
    dat_name_long %in% 'prissmm_pathology' ~ 'path',
    dat_name_long %in% 'prissmm_tumor_marker' ~ 'mark'
  )

  if (factorize) {
    factor(rtn, levels = fact_order)
  } else {
    rtn
  }
}

ca_all <- multisite_tables %>%
  filter(form_in_extract %in% 'cancer_diagnosis') %>%
  pull(dv_tab) %>%
  .[[1]]

ca_ind <- pull

multisite_tables %<>%
  filter(purrr::map_dbl(dv_tab, nrow) > 0) %>%
  mutate(name = dat_name_to_short(form_in_extract)) %>%
  arrange(name)
