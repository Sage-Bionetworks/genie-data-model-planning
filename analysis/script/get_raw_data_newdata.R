library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

synLogin()

data_file_synid <-
  if (!is.null(qc_config$syn_data$syn_id_inst_file)) {
    qc_config$syn_data$syn_id_inst_file
  } else {
    syn_proj_files <- get_syn_children_df(qc_config$syn_id_inst_folder)
    if (nrow(syn_proj_files) > 1) {
      cli_alert_danger("More than one file in the folder - check this.")
    }
    syn_proj_files$id
  }

cli::cli_alert_info(
  "File for {qc_config$inst} last modified on {synGet(data_file_synid)$properties$modifiedOn}"
)


cur_saver_newdata <- function(
  synid,
  qc_configuration
) {
  cur_dir <- fs::path(
    'data-raw',
    'newly_curated_data',
    qc_configuration$inst
  )

  fs::dir_create(cur_dir)
  synGet(
    entity = synid,
    downloadLocation = cur_dir,
    ifcollision = "overwrite.local"
  )
}

dd_saver <- function(
  synid
) {
  cur_dir <- fs::path(
    'data-raw',
    'newly_curated_data',
    qc_configuration$inst
  )

  fs::dir_create(cur_dir)
  synGet(
    entity = synid,
    downloadLocation = cur_dir,
    ifcollision = "overwrite.local"
  )
}

config_list <-
  qc_config <-
    dd_saver(
      synid = qc_config$syn_id_data_dict
    )

cur_saver(
  synid = data_file_synid
)
