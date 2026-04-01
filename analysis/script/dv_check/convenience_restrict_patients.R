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

# Not sure if I'll do this as a new script or keep it here...
# but the next task is remapping cancer sequence in our cohort to match the legacy ones.  To do this I need a separate unique identifier variable combo for cancer sequence.

leg_all_cancers <- bind_rows(
  tables_legacy$ca_ind,
  tables_legacy$ca_non_ind
)

leg_all_cancers %>%
  count(
    record_id,
    dob_ca_dx_days,
    naaccr_laterality_cd,
    naaccr_clin_stage_cd,
    sort = T
  ) %>%
  filter(n >= 2)

tables_new$ca_ind$naaccr_laterality_cd
tables_legacy$ca_ind$naaccr_laterality_cd

add_cancer_id <- function(dat) {
  dat %>%
    mutate(
      cancer_id = rlang::hash(paste(
        record_id,
        dob_ca_dx_days,
        naaccr_laterality_cd,
        naaccr_clin_stage_cd,
        sep = "|"
      ))
    )
}

# Next steps - get the column types to be similar, then make sure we have a good match between datasets.  Eliminate the people duplicates.  Remap cancer sequence.  Probably easier to just CREATE a cancer sequence first in the new ones (just use the old code and feed it to claude)
