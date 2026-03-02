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

redcap_splitter <- function(
  redcap_data,
  dict,
  keys_in_all_instr = NULL,
  forms_missing_in_redcap = NULL
) {
  keys_in_all_instr <- keys_in_all_instr %||%
    c(
      'record_id',
      'redcap_repeat_instrument',
      'redcap_repeat_instance'
    )

  forms_missing_in_redcap <- forms_missing_in_redcap %||%
    c(
      'curation_initiation_eligibility',
      'patient_characteristics',
      'curation_completion',
      'quality_assurance'
    )

  dict <- dict |>
    mutate(
      form_in_extract = case_when(
        form %in% forms_missing_in_redcap ~ NA_character_,
        T ~ form
      )
    )

  nested_dd <- dict %>%
    tidyr::nest(.by = 'form_in_extract', .key = 'dat_dict_sub')

  nested_dd <- nested_dd |>
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
          redcap_data %>%
            select(
              all_of(keys_in_all_instr),
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

  nested_dd
}


nested_dd <- redcap_splitter(redcap_data = dat_ex, dict = dat_dict)

nested_dd_old <- readr::read_rds(
  '/Users/apaynter/main/projects/genie/bayer_qc/MSK-2026-02-25/data/l1_split/nested_l1.rds'
)

waldo::compare(nested_dd, nested_dd_old)

out_dir_l1 <- path(qc_config$storage_root, 'data', 'l1_split')
fs::dir_create(out_dir_l1)

# It's actually more convenient for me to save this as a list dataframe.
readr::write_rds(
  x = nested_dd,
  file = path(out_dir_l1, 'nested_l1.rds')
)
