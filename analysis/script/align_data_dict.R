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
      .f = ~ colnames(readr::read_csv(.x, n_max = 1))
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
    "nonphi_v388_PRISSMM_Dictionary_NSCLC_BPC_P2.csv"
  )
) %>%
  # jeez these headers suck.
  rename(
    field_name = `Variable / Field Name`,
    form = `Form Name`,
    field_type = `Field Type`,
    # this isn't actually limited to valid values, there's calculations in here for some odd reason:
    choices_calc = `Choices, Calculations, OR Slider Labels`,
    required = `Required Field?`
  ) %>%
  rename_all(~ stringr::str_replace_all(tolower(.x), " ", "_")) %>%
  rename_all(~ stringr::str_replace_all(tolower(.x), "\\?", "")) %>%
  rename_all(
    ~ stringr::str_replace_all(tolower(.x), "_\\(.*\\)", "")
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

# You only require the general variable type, not all the iterations of it.
stub_merge %<>%
  group_by(stub) %>%
  arrange(var) %>%
  mutate(.is_first = row_number() %in% 1) %>%
  ungroup(.)

stub_merge <- left_join(
  stub_merge,
  dat_dict,
  by = c(stub = 'field_name')
) %>%
  rename(field_name = var) %>%
  mutate(required = required & .is_first) %>%
  select(-c(.is_first, stub))

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
    field_note = "Not defined - this row was added to the data dictionary as a processing step",
    field_type = case_when(
      # the completeness checks use 1/2 encoding (assuming on the 1) so we need
      #   to treat them differently than yesno columns.
      str_detect(field_name, 'complete$') ~ 'complete_check',
      T ~ 'text'
    )
  )

dat_dict <- bind_rows(
  dat_dict,
  undefined_vars
)

# Call me crazy but I'm going to declare the primary keys required too.
dat_dict %<>%
  mutate(
    required = case_when(
      field_name %in%
        c('record_id', 'redcap_repeat_instrument', 'redcap_repeat_instance') ~
        TRUE,
      T ~ required
    )
  )

# Between these two types of fixes everything is now in:
if (length(setdiff(all_columns, dat_dict$field_name)) > 0) {
  stop("Unresolved data dictionary errors - please fix.")
}

dttm_cols <- c('pt', 'ca', 'drugs', 'rt', 'path', 'image', 'md')
dttm_cols <- c(
  paste0(dttm_cols, '_start_time'),
  paste0(dttm_cols, '_stop_time')
)

date_cols <- c('cpt_seq_date', 'qa_full_date')

num_cols <- c(
  # all the interval columns:
  "hybrid_death_int",
  "last_oncvisit_int",
  "last_alive_int",
  "last_anyvisit_int",
  "enroll_hospice_int",
  "naaccr_diagnosis_int",
  "naaccr_first_contact_int",
  "ca_cadx_int",
  "rt_start_int",
  "rt_end_int",
  "rt_rt_int",
  "path_rep_int",
  "path_proc_int",
  "path_erprher_add1_int",
  "path_erprher_add2_int",
  "path_erprher_add3_int",
  "path_erprher_add4_int",
  "path_erprher_add5_int",
  "image_scan_int",
  "image_report_int",
  "image_ref_scan_int",
  "md_onc_visit_int",
  "tm_spec_collect_int",
  "cpt_order_int",
  "cpt_report_int",

  # and a few others:
  'birth_year',
  'rt_dose',
  'rt_total_dose'
)

dat_dict %<>%
  mutate(
    col_read_type = case_when(
      # The NAs are an odd bunch.  Some of the drug stuff is NA but it's mostly
      #   the "complete" fields, which seem to use 1/2 coding rather than 0/1.
      is.na(field_type) ~ 'char',
      # This group is fundamentally categorical, but almost all are integers.  Could be read in as numeric or character reasonably.
      field_type %in% c('checkbox', 'dropdown', 'radio', 'complete_check') ~
        'char',
      # This group is not categorical.
      field_type %in% c('text') & field_name %in% num_cols ~ 'numeric',
      field_type %in% c('text') & field_name %in% date_cols ~ 'date',
      field_type %in% c('text') & field_name %in% dttm_cols ~ 'dttm',
      field_type %in% c('text') ~ 'char',
      # it's a further manipulation to go to T/F from y/n, so we'll leave that for now:
      field_type %in% 'yesno' ~ 'char'
    )
  )


dat_dict %<>%
  mutate(
    # the choices_calc field is missing some important stuff we'll want to check.
    valid_val_str = case_when(
      field_type %in% c('checkbox', 'dropdown', 'radio') ~ choices_calc,
      field_type %in% 'yesno' ~ '0, No|1, Yes',
      field_type %in% 'complete_check' ~ '1, No|2, Yes'
    )
  )

# Splits the valid_val_str into more structured list columns for later use.
dat_dict %<>%
  split_valid_values(.)

readr::write_rds(
  dat_dict,
  file = here('data', 'bpc', 'step1-curated', 'aligned_data_dictionary.rds')
)

# Next steps:  Start playing with pointblank.
# The valid value set should now be accessible.  You will probably want to create a data structure to make those cleaner but we'll have to see what a good format for that is.
