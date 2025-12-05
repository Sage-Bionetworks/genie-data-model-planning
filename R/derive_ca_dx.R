derive_ca_dx <- function(
  tab,
  dat_dict_sub
) {
  tab <- column_exclusion_helper_derived(tab)

  rtn <- common_data_derivation_operations(
    dat = tab,
    dict = dat_dict_sub
  )

  rtn %<>%
    mutate(
      dob_ca_dx_days = case_when(
        is.na(ca_cadx_int) ~ naaccr_diagnosis_int,
        T ~ ca_cadx_int
      )
    )

  # Add the record level annotations that are jammed into this data for some reason.
  rtn %<>%
    group_by(record_id) %>%
    mutate(
      n_cancers = n(),
      n_cancers_index = sum(redcap_ca_index %in% "Yes")
    ) %>%
    ungroup(.)

  # rearrange the cancer diagnosis form according to the arcane logic in BPC.
  rtn %<>%
    group_by(record_id) %>%
    # break ties by keeping the order of redcap_ca_seq
    arrange(dob_ca_dx_days, redcap_ca_seq) %>%
    mutate(
      ca_seq = case_when(
        n_cancers %in% 1 ~ 0,
        T ~ 1:n()
      )
    ) %>%
    ungroup(.)

  rtn %<>%
    relocate(ca_seq, .after = record_id)

  return(rtn)
}
