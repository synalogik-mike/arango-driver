library(magrittr)

#' Creates a new document of this collection and returns it
#'
#'
create <- function(.data, key){

  if(class(.data)[1] != "ArangoCollection"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::update function")
  }

  # Creates the cursor and iterate over it to retrieve the entire collection
  connectionString <- .data$.__enclos_env__$private$connection$getConnectionString()
  insertionResult <- httr::POST(paste0(connectionString,"/_api/document/", .data$getName(), "?returnNew=true"),
                                body = list(`_key`=key),
                                encode = "json")
  insertionResponse <- content(insertionResult)

  if(insertionResult$status_code == 409){
    stop("a document with the given key already exists")
  }

  if(insertionResult$status_code != 201 && insertionResult$status_code != 202){
    stop("an error occurred during the creation of the document")
  }

  return(aRango_document$new(connectionString, insertionResponse$new))
}

#' Deletes the given document
#'
#'
delete <- function(.data, document){

  if(class(.data)[1] != "ArangoCollection"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::update function")
  }

  if(class(document)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::update function")
  }

  if(.data$getName() != document$collection()){
    stop("cannot remove this document because it belongs to another collection")
  }

  # Creates the cursor and iterate over it to retrieve the entire collection
  connectionString <- .data$.__enclos_env__$private$connection$getConnectionString()
  deletionResult <- httr::DELETE(paste0(connectionString,"/_api/document/", .data$getName(), "/", document$id()))

  if(deletionResult$status_code != 200 && deletionResult$status_code != 202){
    stop("an error occurred during the deletion of the document")
  }

  return(NULL)
}
