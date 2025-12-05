derive_reg <- function(
  tab,
  dat_dict_sub
) {
  tab <- column_exclusion_helper_derived(tab)

  rtn <- common_data_derivation_operations(
    dat = tab,
    dict = dat_dict_sub
  )

  rtn %<>% drugs_ca_rearrangement(., prefix = '^drugs_ca')

  # Notes:
  # probably need remove _mask columns too - but not yet.
  return(rtn)
}
