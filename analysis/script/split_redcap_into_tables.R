library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

dat_dict <- readr::read_rds(
  path(qc_config$storage_root, 'dict', 'aligned', 'dd.rds')
)

dat_ex <- readr::read_csv(
  dir_ls(path(qc_config$storage_root, 'data', 'l0_raw_redcap')),
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

out_dir_l1 <- path(qc_config$storage_root, 'data', 'l1_split')
fs::dir_create(out_dir_l1)

# It's actually more convenient for me to save this as a list dataframe.
readr::write_rds(
  x = nested_dd,
  file = path(out_dir_l1, 'nested_l1.rds')
)
