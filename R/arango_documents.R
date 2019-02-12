library(jsonlite)
library(httr)
library(R6)

#' 
#' @export
.check_numeric_value <- function(value){
  if(!is.numeric(value)){
    stop("the value must be numeric")
  }
  return(value)
}

#' Returns all the documents belonging to the giving collections
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
documents <- function(.collection){
  
  if(class(.collection)[1] != "ArangoCollection"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::documents function")
  }
  
  documents <- list()
  
  # Creates the cursor and iterate over it to retrieve the entire collection
  connectionString <- .collection$.__enclos_env__$private$connectionStringDatabase
  collectionBatch <- httr::POST(paste0(connectionString,"/_api/cursor"),
                                body = list(
                                  query=paste0("FOR d IN ", .collection$getName(), " RETURN d"),
                                  count = FALSE,
                                  batchSize = 50
                                ),
                                encode = "json")
  cursorResponse <- content(collectionBatch)
  
  if(cursorResponse$code != "200" && cursorResponse$code != "201" ){
    stop("Something were wrong during the retrieval of the documents of this collection (arango cursor not created)")
  }
  
  # Save the cursor id, it is needed for all the subsequent access to the cursor
  cursor <- cursorResponse$id
  
  for(document in cursorResponse$result){
    documents[[document$`_key`]] <- .aRango_document$new(document, connectionString)
  }
  
  # Iterating the entire cursor
  while(cursorResponse$hasMore){
    
    # Requesting next data batch
    collectionBatch <- httr::PUT(paste0(connectionString,"/_api/cursor/",cursor))
    cursorResponse <- content(collectionBatch)
    
    if(cursorResponse$code != "200" && cursorResponse$code != "201" ){
      stop("Something were wrong during the retrieval of the documents of this collection (arango cursor not created)")
    }
    
    for(document in cursorResponse$result){
      documents[[document$`_key`]] <- .aRango_document$new(document, connectionString)
    }
  }
  
  return(documents)
}



#' Creates a new document of this collection and returns it
#'
#' @param .collection the collection where add the new document
#' @param key the key that will be used as unique identifier within the collection for the new document
#'              
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
insert <- function(.collection, key){
  
  if(class(.collection)[1] != "ArangoCollection"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::insert function")
  }
  
  # Creates the cursor and iterate over it to retrieve the entire collection
  connectionString <- .collection$.__enclos_env__$private$connectionStringDatabase
  insertionResult <- httr::POST(paste0(connectionString,"/_api/document/", .collection$getName(), "?returnNew=true"),
                                body = list(`_key`=key),
                                encode = "json")
  insertionResponse <- content(insertionResult)
  
  if(insertionResult$status_code == 409){
    stop("a document with the given key already exists")
  }
  
  if(insertionResult$status_code == 200){
    warning("this is allowed for test purposes, the server should never return 200 on creation")
    return(.aRango_document$new(insertionResponse$new, connectionString))
  }
  
  if(insertionResult$status_code != 201 && insertionResult$status_code != 202){
    stop("an error occurred during the creation of the document")
  }
  
  return(.aRango_document$new(insertionResponse$new, connectionString))
}



#' Updates a document with the given parameters
#'
#'
set <- function(.data, ..., .updateOnly = FALSE){
  
  if(class(.data)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::set function")
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
unset <- function(.data, ...){
  
  if(class(.data)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::unset function")
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
    stop("Only 'ArangoDocument' objects can be processed by aRango::execute function")
  }
  
  # Executing the update of the object
  connectionString <- .data$.__enclos_env__$private$connectionString
  
  updateResult <- httr::PATCH(paste0(connectionString,"/_api/document/", .data$getId()),
                            body = .data$.__enclos_env__$private$documentValues,
                            encode = "json")
  
  if(updateResult$status_code != "200" && updateResult$status_code != "201" 
        && updateResult$status_code != "202" ){
    
    # TODO: in case of reject, here the object updates must be somehow reverted
    stop("Something were wrong during the update of the document")
  }
  
  if(updateResult$status_code == 200){
    warning("this is allowed for test purposes, the server should never return 200 on update execution")
  }
  
  # Updating revision
  updatedObjectInfo <- content(updateResult)
  .data$.__enclos_env__$private$currentRevision <- updatedObjectInfo$`_rev`
  
  return(.data)
}

#' Returns the edge in this collection connecting the document passed as argument, if any.
#' 
#' 
#'
find_edge <- function(.collection, from, to){
  
  if(class(.collection)[1] != "ArangoCollection"){
    stop("Only 'ArangoCollection' objects can be processed by aRango::find_edge function")
  }
  
  if(class(from)[1] == "ArangoDocument" && class(to)[1] == "ArangoDocument"){
    foundEdge <- .collection %>% filter(`_from`=from$getId(), `_to`=to$getId())
    
    if(length(foundEdge) > 0){
      return(foundEdge[[1]])
    }
  }
  else if(class(from)[1] == "character" && class(to)[1] == "character"){
    foundEdge <- .collection %>% 
      filter(`_from`=from, `_to`=to)
    
    if(length(foundEdge) > 0){
      return(foundEdge[[1]])
    }
  }
  else{
    return(NULL) 
  }
}

#' Filter the documents from a collection
#'
#'
filter <- function(.collection, ...){
  
  documents <- list()
  
  if(class(.collection)[1] != "ArangoCollection"){
    stop("Only 'ArangoCollection' objects can be processed by aRango::filter function")
  }

  # Retrieve list and creating the filter to be added to the AQL query
  filterString <- ""
  first <- TRUE
  arguments <- list(...)
  
  for(index in 1:length(arguments)){
    key <- names(arguments[index])
    value <- arguments[[index]]
    
    if(first){
      if(is.numeric(value) || is.logical(value)){
        filterString <- paste0("element.", key, " == ", value)
      }
      else{
        if(grepl(">", value) || grepl("<", value)){
          filterString <- paste0("element.", value)
        }
        else{
          filterString <- paste0("element.", key, " == '", value,"'")
        }
      }
      
      first <- FALSE
    }
    else{
      if(is.numeric(value) || is.logical(value)){
        filterString <- paste0(filterString, " && element.", key, " == ", value)
      }
      else{
        if(grepl(">", value) || grepl("<", value)){
          filterString <- paste0(filterString, " && element.", value)
        }
        else{
          filterString <- paste0(filterString, " && element.", key, " == '", value,"'")
        }
      }
    }
  }
  
  # Execution of the filter
  # Creates the cursor and iterate over it to retrieve the entire collection
  connectionString <- .collection$.__enclos_env__$private$connectionStringDatabase
  collectionBatch <- httr::POST(paste0(connectionString,"/_api/cursor"),
                                body = list(
                                  query=paste0("FOR element IN ", .collection$getName(), 
                                               " FILTER ", filterString,  
                                               " RETURN element"),
                                  count = FALSE,
                                  batchSize = 50
                                ),
                                encode = "json")
  
  cursorResponse <- content(collectionBatch)
  
  if(cursorResponse$code != "200" && cursorResponse$code != "201" ){
    stop("Something were wrong during the retrieval of the documents of this collection (arango cursor not created)")
  }
  
  # Save the cursor id, it is needed for all the subsequent access to the cursor
  cursor <- cursorResponse$id
  
  for(document in cursorResponse$result){
    documents[[document$`_key`]] <- .aRango_document$new(document, connectionString)
  }
  
  # Iterating the entire cursor
  while(cursorResponse$hasMore){
    
    # Requesting next data batch
    collectionBatch <- httr::PUT(paste0(connectionString,"/_api/cursor/",cursor))
    cursorResponse <- content(collectionBatch)
    
    if(cursorResponse$code != "200" && cursorResponse$code != "201" ){
      stop("Something were wrong during the retrieval of the documents of this collection (arango cursor not created)")
    }
    
    for(document in cursorResponse$result){
      documents[[document$`_key`]] <- .aRango_document$new(document, connectionString)
    }
  }
  
  return(documents)
}



#' Deletes the given document
#'
#'
delete <- function(.document){
  
  if(class(.document)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::delete function")
  }
  
  # Creates the cursor and iterate over it to retrieve the entire collection
  connectionString <- .document$.__enclos_env__$private$connectionString
  deletionResult <- httr::DELETE(paste0(connectionString,"/_api/document/", .document$getId()))
  
  if(deletionResult$status_code != 200 && deletionResult$status_code != 202){
    stop("an error occurred during the deletion of the document")
  }
  
  return(TRUE)
}



#' The ArangoDocument class encapsulate the representation and the methods useful to manage
#' the retrieval, representation and updates of specific documents belonging to Arango collections.
#' Each document is strictly related to some collection and within the environment SHOULD exists
#' only one copy of this object.
#'
.aRango_document <- R6Class (
  "ArangoDocument",
  
  public = list(
    
    #' Initialize the arango document
    #'
    #'
    initialize = function(document, connectionString){
      
      private$connectionString <- connectionString
      idSplit <- strsplit(document$`_id`, split = "/")
      
      private$documentValues <- document
      private$currentRevision <- document$`_rev`
      private$documentId <- idSplit[[1]][2]
      private$originalCollection <- idSplit[[1]][1]
      
      # Removing _id, _key and _revision from available values
      private$documentValues$`_id` <- NULL
      private$documentValues$`_rev` <- NULL
      private$documentValues$`_key` <- NULL
    },
    
    getCollection = function(){
      return(private$originalCollection)
    },
    
    getId = function(){
      return(paste0(private$originalCollection,"/",private$documentId))
    },
    
    getKey = function(){
      return(private$documentId)
    },
    
    getRevision = function(){
      return(private$currentRevision)
    },
    
    getValues = function(){
      return(private$documentValues)
    },
    
    getAvailableValues = function(){
      return(names(private$documentValues))
    }
  ),
  
  private = list(
    documentValues = NULL,
    originalCollection = NULL,
    documentId = NULL,
    currentRevision = NULL,
    connectionString = NULL
  )
)