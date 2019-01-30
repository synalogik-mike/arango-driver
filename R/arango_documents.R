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