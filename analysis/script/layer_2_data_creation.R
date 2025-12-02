# Layer 2 is the derived versions of the split data.
# This includes derived variables, variable typing, etc.
purrr::walk(.x = fs::dir_ls(here::here("R")), .f = source)

site_to_qc <- "DFCI"
dir_output <- here('data', 'qc', site_to_qc, 'layer_2_datasets')
fs::dir_create(dir_output)

nested_dat <- readr::read_rds(
  here('data', 'qc', site_to_qc, 'layer_1_datasets', 'nested_l1.rds')
)

extract_help <- function(nd, form, to_extract = 'tab') {
  nd %<>% filter(form_in_extract %in% form)
  if (to_extract %in% 'tab') {
    nd %>% pull(tab) %>% .[[1]]
  } else if (to_extract %in% 'dd') {
    nd %>% pull(dat_dict_sub) %>% .[[1]]
  } else {
    cli_abort("to_extract should either be 'tab' or 'dd'.")
  }
}

# The coding in this script is intentionally verbose.
# These functions, such as derive_ca_dx() are bound to become monstrously large over time.
# If we call them in some massive purrr call it will probably get in the way of diagnosis as we work.

###########
# Patient #
###########

proto_pt <- extract_help(
  nd = nested_dat,
  form = 'patient',
  to_extract = 'tab'
)
proto_pt_dd <- extract_help(
  nd = nested_dat,
  form = 'patient',
  to_extract = 'dd'
)
derived_pt <- derive_pt(
  tab = proto_pt,
  dat_dict_sub = proto_pt_dd
)
readr::write_rds(
  derived_pt,
  here(dir_output, 'pt.rds')
)

#############################
# Cancer tables (index/non) #
#############################

proto_ca_dx <- extract_help(
  nd = nested_dat,
  form = 'cancer_diagnosis',
  to_extract = 'tab'
)
proto_ca_dx_dd <- extract_help(
  nd = nested_dat,
  form = 'cancer_diagnosis',
  to_extract = 'dd'
)
derived_ca_dx <- derive_ca_dx(
  tab = proto_ca_dx,
  dat_dict_sub = proto_ca_dx_dd
)
# To split into index and nonindex cases we just do a filter:
ca_ind <- derived_ca_dx %>%
  filter(redcap_ca_index %in% "Yes") %>%
  select(-redcap_ca_index)
ca_non_ind <- derived_ca_dx %>%
  filter(redcap_ca_index %in% "No") %>%
  select(-redcap_ca_index)
# Note: there are some that have redcap_ca_index NA - not sure what's up there.
readr::write_rds(
  ca_ind,
  here(dir_output, 'ca_ind.rds')
)
readr::write_rds(
  ca_non_ind,
  here(dir_output, 'ca_non_ind.rds')
)


###########
# Regimen #
###########

proto_reg <- extract_help(
  nd = nested_dat,
  form = 'ca_directed_drugs',
  to_extract = 'tab'
)
proto_reg_dd <- extract_help(
  nd = nested_dat,
  form = 'ca_directed_drugs',
  to_extract = 'dd'
)
derived_reg <- derive_reg(
  tab = proto_reg,
  dat_dict_sub = proto_reg_dd
)
readr::write_rds(
  derived_reg,
  here(dir_output, 'reg.rds')
)

#############
# Radiation #
#############

proto_rad <- extract_help(
  nd = nested_dat,
  form = 'ca_directed_radtx',
  to_extract = 'tab'
)
proto_rad_dd <- extract_help(
  nd = nested_dat,
  form = 'ca_directed_radtx',
  to_extract = 'dd'
)
derived_rad <- derive_rad(
  tab = proto_rad,
  dat_dict_sub = proto_rad_dd
)
readr::write_rds(
  derived_rad,
  here(dir_output, 'rad.rds')
)


#############
# Pathology #
#############

proto_path <- extract_help(
  nd = nested_dat,
  form = 'prissmm_pathology',
  to_extract = 'tab'
)
proto_path_dd <- extract_help(
  nd = nested_dat,
  form = 'prissmm_pathology',
  to_extract = 'dd'
)
derived_path <- derive_path(
  tab = proto_path,
  dat_dict_sub = proto_path_dd
)
readr::write_rds(
  derived_path,
  here(dir_output, 'path.rds')
)


###########
# Imaging #
###########

proto_img <- extract_help(
  nd = nested_dat,
  form = 'prissmm_imaging',
  to_extract = 'tab'
)
proto_img_dd <- extract_help(
  nd = nested_dat,
  form = 'prissmm_imaging',
  to_extract = 'dd'
)
derived_img <- derive_img(
  tab = proto_img,
  dat_dict_sub = proto_img_dd
)
readr::write_rds(
  derived_img,
  here(dir_output, 'img.rds')
)

###########
# Med Onc #
###########

proto_med_onc <- extract_help(
  nd = nested_dat,
  form = 'prissmm_med_onc_assessment',
  to_extract = 'tab'
)
proto_med_onc_dd <- extract_help(
  nd = nested_dat,
  form = 'prissmm_med_onc_assessment',
  to_extract = 'dd'
)
derived_med_onc <- derive_med_onc(
  tab = proto_med_onc,
  dat_dict_sub = proto_med_onc_dd
)
readr::write_rds(
  derived_med_onc,
  here(dir_output, 'med_onc.rds')
)

# While the tumor marker data is specified in the data dictionary, its got zero rows in the data.

#####################
# Cancer Panel Test #
#####################

proto_cpt <- extract_help(
  nd = nested_dat,
  form = 'cancer_panel_test',
  to_extract = 'tab'
)
proto_cpt_dd <- extract_help(
  nd = nested_dat,
  form = 'cancer_panel_test',
  to_extract = 'dd'
)
derived_cpt <- derive_cpt(
  tab = proto_cpt,
  dat_dict_sub = proto_cpt_dd
)
readr::write_rds(
  derived_cpt,
  here(dir_output, 'cpt.rds')
)
