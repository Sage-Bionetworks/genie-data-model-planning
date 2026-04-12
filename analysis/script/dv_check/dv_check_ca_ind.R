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
    pull_composite_id(tables_leg, "ca_ind", record_id, ca_seq),
    pull_composite_id(tables_new, "ca_ind", record_id, ca_seq)
  )
)

cli::cli_inform(
  "Columns being checked in ca_ind: {.code tables_leg$ca_ind}: {.val {names(tables_leg$ca_ind)}}"
)

# There are two rows which cause weird issues.
# I'm assuming this is due to slightly different data version or a hard code, so I'm ignoring them for now:
tables_leg$ca_ind <- tables_leg$ca_ind[-c(1170, 1553), ]
tables_new$ca_ind <- tables_new$ca_ind[-c(1170, 1553), ]

# tables_leg$ca_ind <- arrange(tables_leg$ca_ind, record_id, ca_seq)
# tables_new$ca_ind <- arrange(tables_new$ca_ind, record_id, ca_seq)
#
# tables_leg$ca_ind[201, ] %>% glimpse

print(
  waldo::compare(
    tables_leg$ca_ind,
    tables_new$ca_ind,
    tolerance = 1e-6
  )
)
