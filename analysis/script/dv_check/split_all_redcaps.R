library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

dd_path <- path('data', 'dv', 'aligned_dd', 'dd_nested.rds')

cur_stub <- here('data-raw', 'bpc', 'step1-curated', 'NSCLC2')

# manual entry on these...
cur_dat_mani <- tribble(
  ~phase,
  ~site,
  ~path,

  2,
  'DFCI',
  path(cur_stub, 'DFCI', '2024-01-30 NSCLC Phase 2 New Submission.csv'),

  2,
  'MSK',
  path(cur_stub, 'MSK', 'BPC_MSK_NSCLCPh2_Full Cohort_09-May-2025.csv'),

  2,
  'UHN',
  path(
    cur_stub,
    'UHN',
    'UHN NSCLC Phase 2 Cohort Production Post Comples Queries Round 1.csv'
  ),

  2,
  'VICC',
  path(cur_stub, 'VICC', 'VICC_GENIEBPCNSCLCPhase2_20240824_reviewed.csv')
)

dd_nested <- readr::read_rds(dd_path)

redcap_splitter(
  filter(cur_dat_mani, site %in% "DFCI")$path,
  filter(dd_nested, site %in% "DFCI")$aligned_dd[[1]]
) %>%
  lobstr::obj_size(.)


nested_dd <- redcap_splitter(redcap_data = dat_ex, dict = dat_dict)

out_dir_l1 <- path(qc_config$storage_root, 'data', 'l1_split')
fs::dir_create(out_dir_l1)

# It's actually more convenient for me to save this as a list dataframe.
readr::write_rds(
  x = nested_dd,
  file = path(out_dir_l1, 'nested_l1.rds')
)
