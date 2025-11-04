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
  key_cols = c(
    "record_id",
    "redcap_repeat_instrument",
    "redcap_repeat_instance"
  )
) {
  if (length(extracts) > 0) {
    rtn <- inner_join(
      val_sub,
      mutate(bind_rows(extracts, .id = 'i'), i = as.integer(i)),
      by = 'i'
    )
    rtn %>%
      select(all_of(colnames(val_sub)), all_of(key_cols))
  } else {
    rtn <- NULL
  }

  rtn
}

qc_res %<>%
  mutate(
    issues = purrr::pmap(
      .l = list(
        val_sub = validation_subset,
        extracts = extracts
      ),
      .f = list_issues
    )
  )

issues_list <- qc_res %>%
  select(qc_layer, dat_name, issues) %>%
  unnest(issues)


dir_out <- here('data', 'qc', site_to_qc, 'qc_issues')
fs::dir_create(dir_out)

readr::write_excel_csv(
  issues_list,
  # could add the date or something if desired for uniqueness.
  here(dir_out, paste0(site_to_qc, '_issues.csv'))
)
