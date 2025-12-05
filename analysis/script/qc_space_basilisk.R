# space because it's a sparse dataset, and basilisk because it causes death in those who look into it.

site_to_qc <- "DFCI"

library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

curated_path <- here('data-raw', 'bpc', 'step1-curated', 'NSCLC2')

dat_ex <- readr::read_csv(
  dir_ls(here(curated_path, site_to_qc)),
  # read everything as a character at this stage:
  col_types = cols(.default = col_character())
)

# cli_alert_danger('Adding errors for demonstration')
# dat_ex <- add_errors_for_demo(dat_ex)

dat_dict <- readr::read_rds(
  here('data', 'bpc', 'step1-curated', 'aligned_data_dictionary.rds')
)

# space because it's a sparse dataset, and basilisk because it causes death in those who look into it.
basil_agent <- create_agent_space_basilisk(
  dat_dict = dat_dict,
  dat_basil = dat_ex
)

basil_intel <- basil_agent %>% pointblank::interrogate(progress = F)

basil_sum <- make_agent_table_row(
  dat_dict = dat_dict,
  interrogated_agent = basil_intel,
  qc_layer = 0,
  site_to_qc = site_to_qc
)

# lobstr::obj_sizes(!!!basil_sum) # coolest pattern ever.

fs::dir_create(here('data', 'qc', site_to_qc, 'qc_results'))

readr::write_rds(
  basil_sum,
  here('data', 'qc', site_to_qc, 'qc_results', 'l0_space.rds')
)

# basil_intel

# all_passed(basil_intel)
# get_agent_report(hydra_intel, display_table = TRUE) # a gt table
# export_report(hydra_intel, filename = 'report-demo.html')
