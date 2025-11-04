agent_start <- function(
  dat,
  table_name,
  log_file = NULL,
  unique_row_def = c(
    'record_id',
    'redcap_repeat_instrument',
    'redcap_repeat_instance'
  )
) {
  if (is.null(log_file)) {
    cust_act_lev <- action_levels(
      warn_at = 1
    )
  } else {
    cust_act_lev <- action_levels(
      warn_at = list(
        warn = ~ log4r_step(
          x,
          append_to = log_file
        )
      )
    )
  }

  cust_agent <- dat %>%
    pointblank::create_agent(
      tbl_name = table_name,
      actions = cust_act_lev
    ) %>%
    pointblank::rows_distinct(
      columns = c(
        'record_id',
        'redcap_repeat_instrument',
        'redcap_repeat_instance'
      )
    )

  return(cust_agent)
}
