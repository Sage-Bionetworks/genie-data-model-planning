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

# This is a bit excessively complicated though, and only needed if we want to attribute columns in the source data to a specific release table.  To see if the column exists we can actually just check out the column names.

colnames(test_data)

# Repeat over the merged files, do a similar process for releases, and see what's different.
