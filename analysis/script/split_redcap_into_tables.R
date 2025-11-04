library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

site_to_qc <- "DFCI"

dat_dict <- readr::read_rds(
  here('data', 'bpc', 'step1-curated', 'aligned_data_dictionary.rds')
)

curated_path <- here('data-raw', 'bpc', 'step1-curated', 'NSCLC2')

dat_ex <- readr::read_csv(
  dir_ls(here(curated_path, site_to_qc)),
  # read everything as a character at this stage:
  col_types = cols(.default = col_character())
)

# the primary keys.
vars_in_all_data <- c(
  'record_id',
  'redcap_repeat_instrument',
  'redcap_repeat_instance'
)

# Some of the "form" entries in the dictionary don't actually come in that way in the data.  Specifically these "forms" show up in the NA form in the data.
# Originally I checked this by looking where the data was non-missing for the first field or two in the the data dictionary "form" groups.
dat_dict %<>%
  mutate(
    form_in_extract = case_when(
      form %in% 'curation_initiation_eligibility' ~ NA_character_,
      form %in% 'patient_characteristics' ~ NA_character_,
      form %in% 'curation_completion' ~ NA_character_,
      form %in% 'quality_assurance' ~ NA_character_,
      T ~ form
    )
  )


nested_dd <- dat_dict %>%
  tidyr::nest(.by = 'form_in_extract', .key = 'dat_dict_sub')

nested_dd %<>%
  mutate(
    var_list = purrr::map(
      dat_dict_sub,
      .f = \(x) x$field_name
    )
  )

nested_dd %<>%
  mutate(
    tab = purrr::map2(
      .x = form_in_extract,
      .y = var_list,
      .f = \(f, v) {
        dat_ex %>%
          select(
            all_of(vars_in_all_data),
            any_of(v)
          ) %>%
          filter(redcap_repeat_instrument %in% f)
      }
    )
  )

nested_dd %<>%
  mutate(
    form_in_extract = case_when(
      # This eventually becomes the "patient level" file.
      is.na(form_in_extract) ~ "patient",
      T ~ form_in_extract
    )
  )

# It's actually more convenient for me to save this as a list dataframe.
readr::write_rds(
  x = nested_dd,
  file = here('data', 'qc', 'DFCI', 'layer_1_datasets', 'nested_l1.rds')
)

# But if you wanted to instead save individual files no problem, just do:
# purrr::walk2(
#   .x = nested_dd$tab,
#   .y = nested_dd$form_in_extract,
#   .f = \(x, y) {
#     readr::write_rds(
#       x = x,
#       file = here('data', 'qc', 'DFCI', 'layer_1_datasets', paste0(y, '.rds'))
#     )
#   }
# )
