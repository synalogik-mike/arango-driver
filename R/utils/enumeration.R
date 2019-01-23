#' Function that allows to define an enumeration in Java-like style.
#'
#'@param ... unique values that define the enumeration set
#'
#'@references https://stackoverflow.com/questions/33838392/enum-like-arguments-in-r
#'@author AEF (StackOverflow user)
Enum <- function(...) {

  values <- sapply(match.call(expand.dots = TRUE)[-1L], deparse)

  stopifnot(identical(unique(values), values))

  res <- setNames(seq_along(values), values)
  res <- as.environment(as.list(res))
  lockEnvironment(res, bindings = TRUE)
  res
}
