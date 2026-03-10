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
script_runner('split_all_redcaps.R')
script_runner('derive_all_tables.R')

# Load the new derived tables:
multi_tab_new <- readr::read_rds(
  here('data', 'dv', 'layer_2_derived_tables', 'multisite_tables.rds')
)

pt_new <- multi_tab_new %>%
  filter(form_in_extract %in% 'patient') %>%
  pull(dv_tab) %>%
  .[[1]]

dir_nsclc_3.1 <- here(
  'data-raw',
  'bpc',
  'step4-release',
  'NSCLC',
  '3.1-consortium'
)

pt_legacy <- readr::read_csv(
  here(dir_nsclc_3.1, 'patient_level_dataset.csv')
) %>%
  filter(phase %in% "Phase II")

setdiff(pt_legacy$record_id, pt_new$record_id)

pt_in_new_not_legacy <- setdiff(pt_new$record_id, pt_legacy$record_id)

pt_new %>%
  filter(record_id %in% pt_in_new_not_legacy) %>%
  ggplot(aes(x = birth_year)) +
  geom_histogram(binwidth = 5, fill = "steelblue", color = "white") +
  labs(
    title = "Birth Year of Patients in pt_new but not in pt_legacy",
    x = "Birth Year",
    y = "Count"
  ) +
  theme_minimal()

# hrmmm that's odd.
