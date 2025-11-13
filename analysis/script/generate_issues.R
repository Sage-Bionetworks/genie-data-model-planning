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

# For now all the datasets have the same key.  This may need to change if this is not the case in the future.

list_issues <- function(
  val_sub,
  extracts,
  report,
  key_cols = c(
    "record_id",
    "redcap_repeat_instrument",
    "redcap_repeat_instance"
  )
) {
  if (length(extracts) > 0) {
    info_on_the_checks <- full_join(
      val_sub,
      select(
        report,
        i,
        type,
        columns,
        values,
        precon
      ),
      by = 'i',
      relationship = 'one-to-one'
    )

    failed_cases <- bind_rows(
      extracts,
      .id = 'i'
    ) %>%
      mutate(i = as.integer(i))

    rtn <- inner_join(
      select(failed_cases, i, all_of(key_cols)),
      info_on_the_checks,
      by = 'i',
      relationship = 'many-to-one'
    )
  } else {
    rtn <- NULL
  }

  rtn
}

qc_test <- qc_res %>% filter(dat_name %in% "cancer_diagnosis")
iss_test <- list_issues(
  val_sub = qc_test$validation_subset[[1]],
  extracts = qc_test$extracts[[1]],
  report = qc_test$report[[1]]
)


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
  here(dir_out, paste0(site_to_qc, '_issues.csv'))
)
