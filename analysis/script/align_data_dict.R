library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

# library(stringdist)

# Just as an example, MSK NSCLC2 data
curated_path <- dir_ls(path(qc_config$storage_root, 'data', 'l0_raw_redcap'))
dd_path <- dir_ls(path(qc_config$storage_root, 'dict', 'raw'))

all_columns <- curated_path %>%
  readr::read_csv(., n_max = 1) %>%
  trim_nameless_cols(.) %>%
  colnames(.)


dd_readr <- function(dat_dict_path) {
  dat_dict <- readr::read_csv(
    dat_dict_path
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

  dat_dict <- dat_dict %>%
    mutate(
      choices_calc = case_when(
        field_type %in% 'checkbox' ~ paste0('0, 0 |', choices_calc)
      )
    )

  return(dat_dict)
}

find_stubs_in_data <- function(dat_cols) {
  stub_vars <- tibble(
    stub = dat_cols %>%
      .[str_detect(., '\\_\\_')]
  ) %>%
    separate(stub, into = c('stub', 'num'), sep = '\\_\\_\\_') %>%
    mutate(num = as.numeric(num)) %>%
    group_by(stub) %>%
    summarize(
      min = min(num),
      max = max(num)
    )

  return(stub_vars)
}


expand_stub_variables <- function(dd, dat_cols) {
  stub_vars <- find_stubs_in_data(dat_cols)

  stub_vars %<>%
    mutate(
      closest = find_closest_str(stub, dict = dd$field_name),
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
    dd,
    by = c(stub = 'field_name')
  ) %>%
    rename(field_name = var) %>%
    mutate(required = required & .is_first) %>%
    select(-c(.is_first, stub))

  stub_merge
}

add_undefined_vars <- function(dat_dict, undefined_vars = NULL) {
  if (is.null(undefined_vars)) {
    undefined_vars <- c(
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
  }

  undefined_vars_df <- tibble(
    field_name = undefined_vars
  )

  undefined_vars_df %<>%
    mutate(
      field_note = "Not defined - this row was added to the data dictionary as a processing step",
      field_type = case_when(
        # the completeness checks use 0/1/2 encoding (assuming on the 1) so we need
        #   to treat them differently than yesno columns.
        str_detect(field_name, 'complete$') ~ 'complete_check',
        T ~ 'text'
      )
    )

  dat_dict <- bind_rows(
    dat_dict,
    undefined_vars_df
  )

  dat_dict
}


dd_assign_coltypes <- function(
  dd,
  dttm_cols = NULL,
  date_cols = NULL,
  num_cols = NULL
) {
  if (is.null(dttm_cols)) {
    dttm_cols <- c('pt', 'ca', 'drugs', 'rt', 'path', 'image', 'md')
    dttm_cols <- c(
      paste0(dttm_cols, '_start_time'),
      paste0(dttm_cols, '_stop_time')
    )
  }

  date_cols <- date_cols %||% c('cpt_seq_date', 'qa_full_date')

  if (is.null(num_cols)) {
    num_cols <- c(
      'redcap_ca_seq',
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
  }

  dd %<>%
    mutate(
      col_read_type = case_when(
        # The NAs are an odd bunch.  Some of the drug stuff is NA but it's mostly
        #   the "complete" fields, which seem to use 0/1/2 coding.
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

  dd
}

align_data_dictionary <- function(
  path_to_cur_dat,
  path_to_dat_dict,
  undefined_vars = NULL,
  required_override = NULL,
  dttm_cols = NULL,
  date_cols = NULL,
  num_cols = NULL
) {
  required_override <- required_override %||%
    c('record_id', 'redcap_repeat_instrument', 'redcap_repeat_instance')

  dat_dict <- dd_readr(dd_path)

  dat_cols <- curated_path %>%
    readr::read_csv(., n_max = 1) %>%
    trim_nameless_cols(.) %>%
    colnames(.)

  # Data dictionary lists variables without the triple underscore + number extension.  This expands it out to include those.
  exp_stubs <- expand_stub_variables(dat_dict, dat_cols = all_columns)
  stub_names <- find_stubs_in_data(dat_cols = all_columns)
  dat_dict <- bind_rows(
    dat_dict,
    exp_stubs
  ) %>%
    filter(!(field_name %in% stub_names$stub))

  dat_dict <- add_undefined_vars(dat_dict, undefined_vars = undefined_vars)

  dat_dict %<>%
    mutate(
      required = case_when(
        field_name %in% required_override ~ TRUE,
        T ~ required
      )
    )

  if (length(setdiff(dat_cols, dat_dict$field_name)) > 0) {
    stop("Unresolved data dictionary errors - please fix.")
  }

  dat_dict <- dd_assign_coltypes(
    dd,
    dttm_cols = dttm_cols,
    date_cols = date_cols,
    num_cols = num_cols
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

  dat_dict %<>%
    split_valid_values(.)

  dat_dict
}

aligned_dd <- align_data_dictionary(
  path_to_cur_dat = curated_path,
  path_to_dat_dict = dd_path
)


out_path <- path(qc_config$storage_root, 'dict', 'aligned')
fs::dir_create(out_path)

readr::write_rds(
  dat_dict,
  file = here(qc_config$storage_root, 'dict', 'aligned', 'dd.rds')
)
