common_data_derivation_operations <- function(
  dat,
  dict,
  print_cols = F
) {
  rtn <- convert_dat_num2val(
    dict = dict,
    dat = dat,
    print_cols = print_cols
  )

  # Where col_read_type is numeric, cast it:
  convert_dat_col_types(
    dict = dict,
    dat = rtn,
    print_cols = print_cols
  )
}
