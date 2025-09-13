# Main workflow for the project.

source(here('analysis', 'script', 'create_folders.R'))
source(here('analysis', 'script', 'get_raw_data.R')) # takes a while to run.
source(here('analysis', 'script', 'extract_variables.R'))
