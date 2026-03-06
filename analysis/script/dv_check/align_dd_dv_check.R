library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

dd_path <- here(
  'data-raw',
  'curated-manual',
  'nonphi_v388_PRISSMM_Dictionary_NSCLC_BPC_P2.csv'
)

cur_stub <- here('data-raw', 'bpc', 'step1-curated', 'NSCLC2')

alignment_manifest <- tibble(
  dd_path = dd_path,
  cur_path = c(
    path(cur_stub, 'DFCI', '2024-01-30 NSCLC Phase 2 New Submission.csv'),
    path(cur_stub, 'MSK', 'BPC_MSK_NSCLCPh2_Full Cohort_09-May-2025.csv'),
    path(
      cur_stub,
      'UHN',
      'UHN NSCLC Phase 2 Cohort Production Post Comples Queries Round 1.csv'
    ),
    path(cur_stub, 'VICC', 'VICC_GENIEBPCNSCLCPhase2_20240824_reviewed.csv')
  )
)

aligned_test <- align_data_dictionary(
  path_to_cur_dat = alignment_manifest$cur_path[[1]],
  path_to_dat_dict = alignment_manifest$dd_path[[1]]
)


aligned_dd <- align_data_dictionary(
  path_to_cur_dat = curated_path,
  path_to_dat_dict = dd_path
)

out_path <- path(qc_config$storage_root, 'dict', 'aligned')
fs::dir_create(out_path)

readr::write_rds(
  aligned_dd,
  file = here(qc_config$storage_root, 'dict', 'aligned', 'dd.rds')
)
