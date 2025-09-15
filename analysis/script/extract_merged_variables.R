dir_merged <- here('data-raw', 'bpc', 'step2-merged')

test_data <- readr::read_csv(
  here(dir_merged, 'BLADDERBPCIntake_data.csv')
)


test_data$redcap_repeat_instrument %>% unique # oh I know those
count(test_data, redcap_repeat_instrument, redcap_repeat_instance) %>%
  group_by(redcap_repeat_instrument) %>%
  arrange(desc(redcap_repeat_instance)) %>%
  slice(1) %>%
  ungroup(.)
# Ok so we get the idea - lots of entries ("repeats") for stuff like med onc, and imaging and fewer for cpt/dx.  I think I get the idea.

# Take all the "data" files (the IRR ones are just subsets with dupes) and read
merged_cohorts <- dir(dir_merged)[stringr::str_detect(
  dir(dir_merged),
  "data.csv$"
)] %>%
  tibble(file = .) %>%
  mutate(
    path = here(dir_merged, file)
  )

# This takes a while because the REDcap export storage format is pointelessly sparse.  The resulting data will be about 5GB - absolutely rediculous.
merged_cohorts <- merged_cohorts %>%
  mutate(
    dat = purrr::map(
      .x = path,
      .f = \(x) readr::read_csv(file = x)
    )
  )

lobstr::obj_size(merged_cohorts)

# Takes a tibble and extracts some information about all the columns.
var_extractor <- function(
  dat,
  missing_levels = ""
) {
  extra_wide <- dat %>%
    summarize(
      across(
        .cols = everything(),
        .fns = list(
          SSEEPP_present = \(x) TRUE,
          SSEEPP_n_vals = \(x) length(unique(x)),
          SSEEPP_n_missing = \(x) sum(is.na(x) | x %in% missing_levels)
        )
      )
    )

  extra_wide %>%
    pivot_longer(cols = everything()) %>%
    separate(col = name, into = c('var', 'colname'), sep = "_SSEEPP_") %>%
    pivot_wider(
      names_from = colname,
      values_from = value
    )
}

test_ext <- var_extractor(test_data)

test_ext %>%
  pivot_longer(cols = everything()) %>%
  separate(col = name, into = c('var', 'colname'), sep = "_SSEEPP_") %>%
  pivot_wider(
    names_from = colname,
    values_from = value
  )


# Stub on trying to assign the data to datasets, which can probably be obviated by downloading the tables (whatever they were called)
nest_data <- test_data %>%
  nest(.by = redcap_repeat_instrument)

nest_data %>%
  filter(redcap_repeat_instrument %in% "Prissmm Imaging") %>%
  pull(data) %>%
  .[[1]] %>%
  map_dbl(
    .x = .,
    .f = \(x) mean(is.na(x))
  )
# Then filter down to the columns with less than 100% missingness to find the ones that are "really there".
