# Main workflow for the project.

library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

script_runner <- function(
  name
) {
  source(here('analysis', 'script', name))
  invisible(name)
}


script_runner('create_folders.R')
# script_runner('get_raw_data.R') # not required to do all this.

# Different workflow not requiring the release analysis:
script_runner('align_data_dict.R')
script_runner('qc_space_basilisk.R')
script_runner('split_redcap_into_tables.R')

# Probably add a check here that the splitting went OK.

# Layer 1 checks:
script_runner('qc_l1_patient.R')
script_runner('qc_l1_cancer_diagnosis.R')
script_runner('qc_l1_ca_directed_drugs.R')
script_runner('qc_l1_ca_directed_radtx.R')
script_runner('qc_l1_prissmm_pathology.R')
script_runner('qc_l1_prissmm_imaging.R')
script_runner('qc_l1_prissmm_med_onc_assessment.R')
script_runner('qc_l1_prissmm_tumor_marker.R')
script_runner('qc_l1_cancer_panel_test.R')

# Create the layer 2 datasets:
script_runner('layer_2_data_creation.R')

# It's valid but probably not common to add level 2 dataset issues if needed.

script_runner('qc_l3_cpt_LJ_ca_all.R')
script_runner('qc_l3_rad_LJ_ca_all.R')
script_runner('qc_l3_reg_LJ_ca_all.R')


script_runner('summarize_testing.R')
