library(geniedv)
library(fs)
library(purrr)
purrr::walk(.x = fs::dir_ls(fs::path("R")), .f = source)

tables_new <- readr::read_rds(here(path(
  'data',
  'dv',
  'layer_2_derived_tables',
  'table_list.rds'
)))

dir_nsclc_3.1 <- here(
  'data-raw',
  'bpc',
  'step4-release',
  'NSCLC',
  '3.1-consortium'
)

legacy_reader <- function(file) {
  readr::read_csv(
    here(dir_nsclc_3.1, file)
  ) %>%
    filter(phase %in% "Phase II")
}

tables_legacy <- list(
  pt = legacy_reader('patient_level_dataset.csv'),
  ca_ind = legacy_reader('cancer_level_dataset_index.csv'),
  ca_non_ind = legacy_reader('cancer_level_dataset_non_index.csv'),
  reg = legacy_reader('regimen_cancer_level_dataset.csv'),
  rad = legacy_reader('ca_radtx_dataset.csv'),
  path = legacy_reader('pathology_report_level_dataset.csv'),
  img = legacy_reader('imaging_level_dataset.csv'),
  med_onc = legacy_reader('med_onc_note_level_dataset.csv'),
  cpt = legacy_reader('cancer_panel_test_level_dataset.csv')
)


restricted <- restrict_to_shared_patients(tables_legacy, tables_new)
tables_legacy <- restricted$tables_legacy
tables_new <- restricted$tables_new

dir_out <- here('data', 'dv', 'layer_2_derived_tables')
readr::write_rds(tables_legacy, path(dir_out, 'restricted_tables_legacy.rds'))
readr::write_rds(tables_new, path(dir_out, 'restricted_tables_new.rds'))
