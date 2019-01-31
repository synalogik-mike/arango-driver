library(jsonlite)
library(httr)
library(R6)


#' Returns all the documents belonging to the giving collections
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
documents <- function(.collection){
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


#' Deletes the given document
#'
#'
delete <- function(.document){
  
  if(class(.document)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::delete function")
  }
  
  # Creates the cursor and iterate over it to retrieve the entire collection
  connectionString <- .document$.__enclos_env__$private$connectionString
  deletionResult <- httr::DELETE(paste0(connectionString,"/_api/document/", .document$getCollection(), "/", .document$getId()))
  
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
    
    #' Update the document
    #'
    #'
    update = function(...){
      
    },
    
    getCollection = function(){
      return(private$originalCollection)
    },
    
    getId = function(){
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