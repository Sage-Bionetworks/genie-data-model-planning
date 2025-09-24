library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

library(stringdist)


# Just as an example, MSK NSCLC2 data
curated_path <- here('data-raw', 'bpc', 'step1-curated', 'NSCLC2')
data_paths <- purrr::map(.x = dir_ls(curated_path), dir_ls)

all_redcap <-
  tibble(
    path = data_paths,
    colnames = purrr::map(
      .x = path,
      .f = ~ colnames(readr::read_csv(.x))
    )
  )

all_columns <- purrr::reduce(
  .x = all_redcap$colnames,
  .f = union
)

dat_dict <- readr::read_csv(
  here(
    'data-raw',
    'curated-manual',
    'v388_PRISSMM_Dictionary_NSCLC_BPC_P2.csv'
  )
) %>%
  # jeez these headers suck.
  rename(
    field_name = `Variable / Field Name`,
    form = `Form Name`,
    field_type = `Field Type`,
    # this isn't actually limited to valid values, there's calculations in here for some odd reason:
    valid_vals = `Choices, Calculations, OR Slider Labels`,
    required = `Required Field?`
  ) %>%
  mutate(
    required = if_else(required %in% "y", T, F) # fixing y/NA coding.
  )

# Lets see if we can find a match for all the double underscore fields.
stub_vars <- tibble(
  stub = all_columns %>%
    .[str_detect(., '\\_\\_')]
) %>%
  separate(stub, into = c('stub', 'num'), sep = '\\_\\_\\_') %>%
  mutate(num = as.numeric(num)) %>%
  group_by(stub) %>%
  summarize(
    min = min(num),
    max = max(num)
  )

stub_vars %<>%
  mutate(
    closest = find_closest_str(stub, dict = dat_dict$field_name),
    exact_match = closest == stub
  )

# Ok great, now we have to fix the data dictionary to accomodate all these:
stub_merge <- stub_vars %>%
  slice(rep(1:n(), times = max)) %>%
  group_by(stub) %>%
  mutate(var = paste0(stub, '___', row_number())) %>%
  ungroup(.) %>%
  select(var, stub)

stub_merge <- left_join(
  stub_merge,
  dat_dict,
  by = c(stub = 'field_name')
) %>%
  select(-stub) %>%
  rename(field_name = var)

dat_dict <- bind_rows(
  dat_dict,
  stub_merge
) %>%
  # not strictly required, but we can remove the stubs now that we have the numbered versions in there:
  filter(!(field_name %in% stub_vars$stub))

# Then there are a few fields that are just hard manual.  No real explanation why these aren't in the data dictionary, but they're not.
# using tribble here just in case I want to add a second or third field.
undefined_vars <- tribble(
  ~field_name,
  'redcap_data_access_group', # sage added.
  'redcap_repeat_instrument',
  'redcap_repeat_instance',
  'curation_initiation_eligibility_complete',
  'patient_characteristics_complete',
  'cancer_diagnosis_complete',
  'ca_directed_drugs_complete',
  'ca_directed_radtx_complete',
  'prissmm_imaging_complete',
  'prissmm_pathology_complete',
  'prissmm_med_onc_assessment_complete',
  'prissmm_tumor_marker_complete',
  'cancer_panel_test_complete',
  'curation_completion_complete',
  'quality_assurance_complete'
)

undefined_vars %<>%
  mutate(
    field_note = "Not defined - this row was added to the data dictionary before QC."
  )

dat_dict <- bind_rows(
  dat_dict,
  undefined_vars
)

# Between these two types of fixes everything is now in:
if (length(setdiff(all_columns, dat_dict$field_name))) {
  stop("Unresolved data dictionary errors - please fix.")
}

readr::write_rds(
  dat_dict,
  file = here('data', 'bpc', 'step1-curated', 'aligned_data_dictionary.rds')
)
