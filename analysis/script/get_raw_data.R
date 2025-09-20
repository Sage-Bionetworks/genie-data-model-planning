library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

synLogin()


################
# Curated data #
################

# folders in the curated folder which are not cohorts.
curated_not_cohorts <- c('HACK - local validator', 'archive', 'retraction')

curated_dat <- get_syn_children_df('syn20852283') |>
  select(cohort = name, cohort_id = id) |>
  filter(!(cohort %in% curated_not_cohorts))

# Go a level deeper to get the site folders.
curated_dat <- curated_dat |>
  mutate(
    children = map(.x = cohort_id, .f = get_syn_children_df)
  ) |>
  unnest(children) |>
  select(contains("cohort"), site = name, site_id = id) |>
  filter(!(site %in% c("archive", "SAGE")))

# One more level for the subfolders
curated_dat <- curated_dat |>
  mutate(
    children = map(.x = site_id, .f = get_syn_children_df)
  ) |>
  unnest(children) |>
  select(
    contains("cohort"),
    contains("site"),
    subfolder = name,
    subfolder_id = id
  )

# Stopping here on the curated.  It's just a gigantic mess, good god.

##########
# Merged #
##########

merged_dat <- get_syn_children_df('syn23286928') |>
  filter(!(name %in% "placeholder"))

merged_saver <- function(
  synid
) {
  synGet(
    entity = synid,
    downloadLocation = here(
      "data-raw",
      'bpc',
      'step2-merged'
    ),
    ifcollision = "overwrite.local"
  )
}

purrr::walk(
  merged_dat$id,
  merged_saver
)

############
# pre-MSKS #
############

# Ready for the super clean URL for the synapse tables?
synid_pmsks <- 'syn21446696'
pmsks_index <- as_tibble(as.data.frame(synTableQuery(
  query = paste0('select * from ', synid_pmsks)
)))

# Check that the table names are unique:
if (any(duplicated(pmsks_index$name))) {
  cli::cli_abort("Duplicated table names - need to resolve")
}

# clicked on the patient characteristics table, for example:

test <- as.data.frame(
  synTableQuery(
    paste0('select * from ', 'syn21446700')
  )
)

save_table_as_csv <- function(
  synid,
  save_file
) {
  dat <- as.data.frame(synTableQuery(
    paste0('select * from ', synid)
  ))
  readr::write_rds(dat, save_file)
}

# for now I'm just going to save them by the table name.
# it might make more sense to build on the form names.
pmsks_index %>%
  select(id, name, form)

save_table_as_csv(
  'syn21446700',
  save_file = here(
    'data-raw',
    'bpc',
    'step3-redacted',
    'patient_characteristics.csv'
  )
)


###########
# Release #
###########

release_not_cohort <- c('Main GENIE cBioPortal Releases')

release_dat <- get_syn_children_df('syn21241322') |>
  select(cohort = name, cohort_id = id) |>
  filter(!(cohort %in% release_not_cohort))

# Go a level deeper
release_dat <- release_dat |>
  mutate(
    children = map(.x = cohort_id, .f = get_syn_children_df)
  ) |>
  unnest(children) |>
  select(contains("cohort"), release = name, release_id = id)

# Just to be safe I'll ignore anything marked sensitive or archived for this.
release_dat <- release_dat |>
  filter(
    !str_detect(
      tolower(release),
      'archived|sensitive'
    )
  )

# For each release we'll go into the folder
release_saver <- function(
  cohort,
  release,
  synid
) {
  subfold <- get_syn_children_df(synid)

  subfold <- subfold |>
    filter(str_detect(name, 'clinical_data'))

  if (nrow(subfold) > 1) {
    cli_abort("Multiple clinical data folders found.")
  } else if (nrow(subfold) < 1) {
    cli_abort("No clinical data folders found.")
  }

  clin_dat_dir <- get_syn_children_df(subfold$id)

  release_helper <- function(
    synid
  ) {
    release_dir <- here(
      "data-raw",
      'bpc',
      'step4-release',
      # because we're defining this function in the context of a single release, this works even though cohort and release aren't arguments.
      cohort,
      release
    )

    fs::dir_create(release_dir)
    synGet(
      entity = synid,
      downloadLocation = release_dir,
      ifcollision = "overwrite.local"
    )
  }

  purrr::walk(
    clin_dat_dir$id,
    release_helper
  )
}

# You could do a single release with the function like this (demo):
# release_saver(
#   cohort = pull(slice(release_dat, 1), cohort),
#   release = pull(slice(release_dat, 1), release),
#   synid = pull(slice(release_dat, 1), release_id)
# )

# We'll do them all at once:
purrr::pwalk(
  .l = list(
    cohort = release_dat$cohort,
    release = release_dat$release,
    synid = release_dat$release_id
  ),
  .f = release_saver
)
