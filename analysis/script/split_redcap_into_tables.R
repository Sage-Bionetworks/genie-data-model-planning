library(fs)
library(purrr)
library(here)
purrr::walk(.x = fs::dir_ls(here("R")), .f = source)

dat_dict <- readr::read_rds(
  path(qc_config$storage_root, 'dict', 'aligned', 'dd.rds')
)

dat_ex <- readr::read_csv(
  dir_ls(path(qc_config$storage_root, 'data', 'l0_raw_redcap')),
  # read everything as a character at this stage:
  col_types = cols(.default = col_character())
)

nested_dd <- redcap_splitter(redcap_data = dat_ex, dict = dat_dict)

out_dir_l1 <- path(qc_config$storage_root, 'data', 'l1_split')
fs::dir_create(out_dir_l1)

# It's actually more convenient for me to save this as a list dataframe.
readr::write_rds(
  x = nested_dd,
  file = path(out_dir_l1, 'nested_l1.rds')
)
