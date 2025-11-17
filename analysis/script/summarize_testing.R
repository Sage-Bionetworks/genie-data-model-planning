library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

site_to_qc <- "DFCI"

qc_res_dir <- here('data', 'qc', site_to_qc, 'qc_results')

qc_res <- tibble(
  file = dir(qc_res_dir),
) %>%
  mutate(
    path = here(qc_res_dir, file),
    dat_name = str_sub(file, 4, -5),
    dat_qc_res = purrr::map(.x = path, .f = readr::read_rds)
  )

qc_res <- qc_res %>%
  select(dat_qc_res) %>%
  unnest(dat_qc_res)

# For now all the datasets
# qc_test <- qc_res %>% filter(dat_name %in% "cancer_diagnosis")
# iss_test <- list_issues(
#   val_sub = qc_test$validation_subset[[1]],
#   extracts = qc_test$extracts[[1]],
#   report = qc_test$report[[1]]
# )

qc_res %<>%
  mutate(
    issues = purrr::pmap(
      .l = list(
        val_sub = validation_subset,
        extracts = extracts,
        report = report
      ),
      .f = list_issues
    )
  )

issues_list <- qc_res %>%
  select(qc_layer, dat_name, issues) %>%
  unnest(issues)

issues_list %<>%
  select(
    qc_layer,
    dat_name,
    assertion_type, # same as "type"
    asserted_values = values,
    columns,
    record_id,
    redcap_repeat_instrument,
    redcap_repeat_instance,
    brief,
    label,
    time_processed,
    agent_i = i
  )


dir_out <- here('data', 'qc', site_to_qc, 'qc_issues')
fs::dir_create(dir_out)

readr::write_excel_csv(
  issues_list,
  # could add the date or something if desired for uniqueness.
  here(dir_out, paste0(site_to_qc, '_issues.csv')),
  na = ""
)

# Additionally we'll want a list of all the tests tat were done:
tests_run <- qc_res %>%
  select(qc_layer, site, dat_name, validation_subset) %>%
  unnest(validation_subset)

readr::write_excel_csv(
  tests_run,
  here(dir_out, paste0(site_to_qc, '_tests_run.csv')),
  na = ""
)
