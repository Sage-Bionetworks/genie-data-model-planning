redcap_numbers_to_meaning <- function(
  vec,
  key_val_pairs,
  remove_names = F
) {
  ind <- match(vec, names(key_val_pairs))
  if (remove_names) {
    names(key_val_pairs) <- NULL
  }
  key_val_pairs[ind]
}
