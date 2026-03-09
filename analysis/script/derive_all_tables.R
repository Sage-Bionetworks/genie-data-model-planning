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
