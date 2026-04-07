derive_ca_seq <- function(dat) {
  rtn <- dat |>
    dplyr::arrange(record_id, ca_cadx_int, redcap_ca_seq) |>
    dplyr::group_by(record_id) |>
    dplyr::mutate(
      dob_ca_dx_days = dplyr::case_when(
        !is.na(ca_cadx_int) ~ ca_cadx_int,
        is.na(ca_cadx_int) & !is.na(naaccr_diagnosis_int) ~ naaccr_diagnosis_int
      ),
      n_cancers = dplyr::n()
    ) |>
    dplyr::arrange(record_id, dob_ca_dx_days) |>
    dplyr::mutate(
      ca_seq = dplyr::case_when(
        n_cancers == 1 ~ 0,
        n_cancers > 1 ~ dplyr::row_number()
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select(-n_cancers)

  return(rtn)
}
