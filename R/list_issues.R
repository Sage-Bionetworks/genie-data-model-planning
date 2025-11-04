list_issues <- function(
  val_sub,
  extracts,
  key_cols
) {
  str(key_cols)
  rtn <- inner_join(
    val_sub,
    mutate(bind_rows(extracts, .id = 'i'), i = as.integer(i)),
    by = 'i'
  )

  rtn %>%
    select(all_of(colnames(val_sub)), all_of(key_cols))
}
