derive_cpt <- function(
  tab,
  dat_dict_sub
) {
  tab <- column_exclusion_helper_derived(tab)

  cpt_ca_cols <- dat_dict_sub %>%
    filter(str_detect(field_name, '^cpt_ca___')) %>%
    pull(field_name)

  rtn <- common_data_derivation_operations(
    dat = tab,
    dict = dat_dict_sub,
    exclude_cols = cpt_ca_cols
  )

  rtn %<>% drugs_ca_rearrangement(., prefix = "^cpt_ca")

  return(rtn)
}
