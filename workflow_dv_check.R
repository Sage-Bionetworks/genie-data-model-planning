# This script will be used for checking our derived variable code against previous work.

library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

script_runner <- function(
  name
) {
  source(here('analysis', 'script', 'dv_check', name))
  invisible(name)
}

script_runner('align_dd_dv_check.R')

# Step 1: create derived variable datasets:

dir_nsclc_3.1 <- here(
  'data-raw',
  'bpc',
  'step4-release',
  'NSCLC',
  '3.1-consortium'
)

pt_legacy <- readr::read_csv(
  here(dir_nsclc_3.1, 'patient_level_dataset.csv')
)
