library(magrittr)

#' Updates a document with the given parameters
#'
#'
filter <- function(.data, ..., .updateOnly = FALSE){

  if(class(.data)[1] != "ArangoCollection"){
    stop("Only 'ArangoCollection' objects can be processed by aRango::filter")
  }

  arguments <- list(...)

  for(key in names(arguments)){
    value <- arguments[[key]]

    .data$.__enclos_env__$private$documentValues[[key]] <- value
  }

  return(.data)
}
