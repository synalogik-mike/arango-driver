library(magrittr)

#' Updates a document with the given parameters
#'
#'
set <- function(.data, ..., .updateOnly = FALSE){

  if(class(.data)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::update function")
  }

  arguments <- list(...)

  for(key in names(arguments)){
    value <- arguments[[key]]

    .data$.__enclos_env__$private$documentValues[[key]] <- value
  }

  return(.data)
}


#' Deletes some values from the given data
#'
#'
remove <- function(.data, ...){

  if(class(.data)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::update function")
  }

  variableToRemove <- c(...)

  for(key in variableToRemove){
    .data$.__enclos_env__$private$documentValues[[key]] <- NULL
  }

  return(.data)
}


#' Excecute the update of a function.
#'
#'
execute <- function(.data){

  if(class(.data)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::update function")
  }

  # Executing the update of the object
  connectionString <- .data$.__enclos_env__$private$connectionString

  updateResult <- httr::PUT(paste0(connectionString,"/_api/document/",.data$collection(), "/", .data$id()),
                                body = .data$.__enclos_env__$private$documentValues,
                                encode = "json")
  updatedObjectInfo <- content(updateResult)

  if(updateResult$status_code != "201" && updateResult$status_code != "202" ){

    # TODO: in case of reject, here the object updates must be somehow reverted
    stop("Something were wrong during the update of the document")
  }

  # Updating revision
  .data$.__enclos_env__$private$currentRevision <- updatedObjectInfo$`_rev`

  return(.data)
}
