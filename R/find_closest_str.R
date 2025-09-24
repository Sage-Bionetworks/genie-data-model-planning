# Find the element in dict which is closest to str by some string distance metric.
find_closest_str <- function(
  str,
  dict,
  method = 'lcs'
) {
  dict[
    stringdist::amatch(
      method = method,
      maxDist = Inf,
      x = str,
      table = dict
    )
  ]
}
