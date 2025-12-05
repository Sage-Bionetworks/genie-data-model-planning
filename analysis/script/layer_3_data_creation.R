purrr::walk(.x = fs::dir_ls(here::here("R")), .f = source)

dir_l2 <- here('data', 'qc', 'DFCI', 'layer_2_datasets')

ca_ind <- readr::read_rds(here(dir_l2, 'ca_ind.rds'))
ca_non_ind <- readr::read_rds(here(dir_l2, 'ca_non_ind.rds'))
ca_all <- readr::read_rds(here(dir_l2, 'ca_all.rds'))
cpt <- readr::read_rds(here(dir_l2, 'cpt.rds'))
img <- readr::read_rds(here(dir_l2, 'img.rds'))
med_onc <- readr::read_rds(here(dir_l2, 'med_onc.rds'))
path <- readr::read_rds(here(dir_l2, 'path.rds'))
pt <- readr::read_rds(here(dir_l2, 'pt.rds'))
rad <- readr::read_rds(here(dir_l2, 'rad.rds'))
reg <- readr::read_rds(here(dir_l2, 'reg.rds'))


rr_vec <- c('record_id', 'redcap_ca_seq')

# yikes.  gotta write a script to process drugs_ca into multiple rows.
cpt_LJ_ca_all <- dplyr::left_join(
  cpt,
  (ca_all %>%
    mutate(row_exists.ca_all = T) %>%
    select(all_of(rr_vec), row_exists.ca_all)),
  by = rr_vec,
  suffix = c('.cpt', '.ca_all'),
  relationship = 'many-to-one'
)

# cpt_LJ_ca_all %>% count(redcap_repeat_instrument.ca_all)
#
# cpt_LJ_ca_all %>%
#   filter(is.na(redcap_repeat_instrument.ca_all)) %>%
#   select(record_id, redcap_ca_seq)

# These are real errors!  cancer sequence 1 doesn't link to cancer sequence NA, sorry, that's not a tolerable fault.

reg_LJ_ca_all <- dplyr::left_join(
  reg,
  (ca_all %>%
    mutate(row_exists.ca_all = T) %>%
    select(all_of(rr_vec), row_exists.ca_all)),
  by = rr_vec,
  suffix = c('.reg', '.ca_all'),
  relationship = 'many-to-one'
)

rad_LJ_ca_all <- dplyr::left_join(
  rad,
  (ca_all %>%
    mutate(row_exists.ca_all = T) %>%
    select(all_of(rr_vec), row_exists.ca_all)),
  by = rr_vec,
  suffix = c('.rad', '.ca_all'),
  relationship = 'many-to-one'
)

# remaining ones I want to do:
# - pt <-> ca_ind full join, should be identical patient cohorts.
# - path -> pt make sure ids good, probably some time stuff later on.
# - med_onc -> pt make sure ids good, probably some time stuff later on.
# - img -> pt make sure ids good, time later.

# pt_FJ_ca_ind <- dplyr::full_join(
#   (pt %>% select(record_id) %>% mutate(row_exists.pt = T)),
#   (ca_ind %>% select(record_id) %>% mutate(row_exists.pt = T)),
# )

# Note: probably better to just create these datasets before you start the script analyzing them for errors.  All the same, good problems.
