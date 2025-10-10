library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

curated_path <- here('data-raw', 'bpc', 'step1-curated', 'NSCLC2')

dat_ex <- readr::read_csv(
  dir_ls(here(curated_path, "DFCI")),
  # read everything as a character at this stage:
  col_types = cols(.default = col_character())
)

dat_dict <- readr::read_rds(
  here('data', 'bpc', 'step1-curated', 'aligned_data_dictionary.rds')
)

# I think the best way to figure out what workflow will suit me is programming some actual checks in:
req_cols <- dat_dict %>%
  filter(required) %>%
  pull(field_name)

comp_chk_cols <- dat_dict %>%
  filter(field_type %in% "complete_check") %>%
  pull(field_name)

# I'm going to go ahead and call those required too:
req_cols <- c(req_cols, comp_chk_cols)


# Add a few problems for the purposes of data checking:
dat_ex %<>% select(-drugs_stop_time) # remove one col
dat_ex <- bind_rows(dat_ex, slice(dat_ex, 2039)) # one dupe row
dat_ex[500, "ca_directed_radtx_complete"] <- "1" # one marked incomplete.


# hydra = the abomination merged data we start with.
hydra_agent <- dat_ex %>%
  # select(-c(pt_start_time, pt_stop_time, redcap_ca_seq)) %>%
  create_agent(
    tbl_name = "REDcap Deep Space data QC",
    actions = action_levels(
      warn_at = 1,
      fns = list(
        warn = ~ log4r_step(
          x,
          append_to = "example_log"
        )
      )
    )
  )

hydra_agent %<>%
  col_exists(columns = all_of(req_cols))

hydra_agent %<>%
  rows_distinct(
    columns = c(
      'record_id',
      'redcap_repeat_instrument',
      'redcap_repeat_instance'
    )
  )

hydra_agent %<>%
  col_vals_in_set(
    columns = comp_chk_cols,
    set = c("2", NA),
    label = "All forms marked complete"
  )

hydra_intel <- hydra_agent %>%
  interrogate()

all_passed(hydra_intel)

get_agent_report(hydra_intel, display_table = TRUE) # a gt table

export_report(hydra_intel, filename = 'report-demo.html')
