# Load the new derived tables:
library(geniedv)
library(fs)
library(purrr)
purrr::walk(.x = fs::dir_ls(fs::path("R")), .f = source)

library(testthat)

restricted_tab_dir <- here('data', 'dv', 'layer_2_derived_tables')
tables_leg <- readr::read_rds(here(
  restricted_tab_dir,
  'comparable_tables_legacy.rds'
))
tables_new <- readr::read_rds(here(
  restricted_tab_dir,
  'comparable_tables_new.rds'
))


scope_dir <- here('analysis', 'script', 'dv_check', 'dv_check_scope')
tables_leg <- apply_column_scope(tables_leg, scope_dir)
tables_new <- apply_column_scope(tables_new, scope_dir)

test_that(
  "Same set of record_id|ca_seq values in ca_ind table",
  expect_setequal(
    pull_composite_id(tables_leg, "path", record_id),
    pull_composite_id(tables_new, "path", record_id)
  )
)

cli::cli_inform(
  "Columns being checked in path: {.code tables_leg$path}: {.val {names(tables_leg$path)}}"
)


tables_leg$path <- arrange(tables_leg$path, record_id, path_proc_int)
tables_new$path <- arrange(tables_new$path, record_id, path_proc_int)

# problem patient:
tables_leg$path <- filter(tables_leg$path, record_id != "GENIE-DFCI-003677")
tables_new$path <- filter(tables_new$path, record_id != "GENIE-DFCI-003677")


# This is a substantial restriction but I can't figure out what the logic is in ordering for path_rep_number so... here we go...
tables_new$path %<>%
  group_by(record_id, path_proc_number) %>%
  mutate(.n_within = n()) %>%
  filter(.n_within %in% 1) %>%
  ungroup(.) %>%
  drop_dots()
tables_leg$path %<>%
  group_by(record_id, path_proc_number) %>%
  mutate(.n_within = n()) %>%
  filter(.n_within %in% 1) %>%
  ungroup(.) %>%
  drop_dots()


# kind of a lot of regions removed for some reason, but 151 out of 30k isn't that alarming.
print(
  waldo::compare(
    tables_leg$path,
    tables_new$path,
    tolerance = 1e-6
  )
)
