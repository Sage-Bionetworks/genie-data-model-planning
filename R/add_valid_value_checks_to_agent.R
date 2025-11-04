add_valid_value_checks_to_agent <- function(
  data_dict,
  ptblank_agent
) {
  valid_val_numeric_code_field_sets <- dict_sub %>%
    filter(!is.na(valid_val_str)) %>%
    group_by(valid_val_key_code) %>%
    summarize(field_names = list(c(field_name)))

  for (i in 1:nrow(valid_val_numeric_code_field_sets)) {
    ptblank_agent %<>%
      col_vals_in_set(
        columns = all_of(
          valid_val_numeric_code_field_sets[[i, "field_names"]][[1]]
        ),
        set = valid_val_numeric_code_field_sets[[i, "valid_val_key_code"]][[1]]
      )
  }

  ptblank_agent
}
