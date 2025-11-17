# for now all datasets have the same key.  This may need to change if this is not the case in the future.

list_issues <- function(
  val_sub,
  extracts,
  report,
  key_cols = c(
    "record_id",
    "redcap_repeat_instrument",
    "redcap_repeat_instance"
  )
) {
  if (length(extracts) > 0) {
    info_on_the_checks <- full_join(
      val_sub,
      select(
        report,
        i,
        type,
        columns,
        values,
        precon
      ),
      by = 'i',
      relationship = 'one-to-one'
    )

    failed_cases <- bind_rows(
      extracts,
      .id = 'i'
    ) %>%
      mutate(i = as.integer(i))

    rtn <- inner_join(
      select(failed_cases, i, all_of(key_cols)),
      info_on_the_checks,
      by = 'i',
      relationship = 'many-to-one'
    )
  } else {
    rtn <- NULL
  }

  rtn
}
