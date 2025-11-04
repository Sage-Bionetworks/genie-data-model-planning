# Main workflow for the project.

library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

source(here('analysis', 'script', 'create_folders.R'))
source(here('analysis', 'script', 'get_raw_data.R')) # not required to do all this.

# Different workflow not requiring the release analysis:
source(here('analysis', 'script', 'align_data_dict.R'))
source(here('analysis', 'script', 'qc_space_basilisk.R'))
source(here('analysis', 'script', 'split_redcap_into_tables.R'))

# Probably add a check here that the splitting went OK.

# Layer 1 checks:
source(here('analysis', 'script', 'qc_l1_patient.R'))
source(here('analysis', 'script', 'qc_l1_cancer_diagnosis.R'))
source(here('analysis', 'script', 'qc_l1_ca_directed_drugs.R'))
source(here('analysis', 'script', 'qc_l1_ca_directed_radtx.R'))
source(here('analysis', 'script', 'qc_l1_prissmm_pathology.R'))
source(here('analysis', 'script', 'qc_l1_prissmm_imaging.R'))
source(here('analysis', 'script', 'qc_l1_prissmm_med_onc_assessment.R'))
source(here('analysis', 'script', 'qc_l1_prissmm_tumor_marker.R'))
source(here('analysis', 'script', 'qc_l1_cancer_panel_test.R'))


# Data splitting file
# Other qc files
source(here('analysis', 'script', 'generate_issues.R'))
