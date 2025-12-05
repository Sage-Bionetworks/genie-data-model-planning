library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

qc_res_dir <- path(qc_config$storage_root, 'result')

qc_res <- tibble(
  file = dir(qc_res_dir),
) %>%
  mutate(
    path = path(qc_res_dir, file),
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

# some manual fixing of output types here:
qc_res %<>%
  mutate(
    issues = purrr::map(
      .x = issues,
      .f = \(x) {
        if (is.null(x)) {
          x
        } else {
          x %>%
            mutate(
              redcap_repeat_instance = as.numeric(redcap_repeat_instance)
            )
        }
      }
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


dir_out <- path(qc_config$storage_root, 'output')

# take the last folder name in the path to help track versions later:
last_folder_name <- str_extract(qc_config$storage_root, '[^\\/]*$')

fs::dir_create(qc_config$storage_root, 'output', 'issues')
readr::write_excel_csv(
  issues_list,
  # could add the date or something if desired for uniqueness.
  path(
    qc_config$storage_root,
    'output',
    'issues',
    paste0(last_folder_name, '_issues.csv')
  ),
  na = ""
)

# Additionally we'll want a list of all the tests tat were done:
tests_run <- qc_res %>%
  select(qc_layer, site, dat_name, validation_subset) %>%
  unnest(validation_subset)

fs::dir_create(qc_config$storage_root, 'output', 'tests_run')
readr::write_excel_csv(
  tests_run,
  path(
    qc_config$storage_root,
    'output',
    'tests_run',
    paste0(last_folder_name, '_tests_run.csv')
  ),
  na = ""
)
