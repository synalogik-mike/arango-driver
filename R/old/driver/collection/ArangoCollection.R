library(jsonlite)
library(httr)
library(R6)

#'
#'
#'
aRango_collection <- R6Class (
  "ArangoCollection",

  public = list(

    #' Creates a new proxy for a collection on the server
    #'
    #' @param arangoConnection an aRango_connection
    #' @param name the name of the collection to proxy
    initialize = function(arangoConnection, name, lazyLoading = TRUE){
      connectionString <- arangoConnection$getConnectionString()
      collectionPropertyResponse <- httr::GET(paste0(connectionString,"/_api/collection/",name,"/count"))
      collectionProperties <- content(collectionPropertyResponse)

      if(collectionProperties$code != "200"){
        stop("Something were wrong during the retrieval of the information for this collection")
      }

      private$connection = arangoConnection
      private$collectionName = name
      private$collectionIdentifier = collectionProperties$id
      private$collectionGlobalUniqueId = collectionProperties$globallyUniqueId
      private$collectionCount = collectionProperties$count
      private$collectionStatus = collectionProperties$statusString
    },

    #' Returns the count of the elements contained into this collection
    #'
    #' @param estimate TRUE iff the count of the vertices collection must be estimated, FALSE iff must be exact
    #'
    #' @return the count of the elements contained into this collection
    count = function(estimate=FALSE){

      if(estimate == FALSE){
        connectionString <- private$connection$getConnectionString()
        collectionPropertyResponse <- httr::GET(paste0(connectionString,"/_api/collection/",private$collectionName,"/count"))
        collectionProperties <- content(collectionPropertyResponse)

        if(collectionProperties$code != "200"){
          stop("Something were wrong during the retrieval of the information for this collection")
        }

        private$collectionCount <- collectionProperties$count

        return(private$collectionCount)
      }

      return(private$collectionCount)
    },

    #' Returns the name of this collection
    #'
    #' @return the name of this collection
    getName = function(){
      return(private$collectionName)
    },

    #' Returns the documents belonging to this collection
    #'
    #' @return the name of this collection
    getAllDocuments = function(){

      documents <- list()

      # Creates the cursor and iterate over it to retrieve the entire collection
      connectionString <- private$connection$getConnectionString()
      collectionBatch <- httr::POST(paste0(connectionString,"/_api/cursor"),
                                    body = list(
                                                query=paste0("FOR d IN ", private$collectionName, " RETURN d"),
                                                count = FALSE,
                                                batchSize = 5
                                           ),
                                    encode = "json")
      cursorResponse <- content(collectionBatch)

      if(cursorResponse$code != "200" && cursorResponse$code != "201" ){
        stop("Something were wrong during the retrieval of the documents of this collection (arango cursor not created)")
      }

      # Save the cursor id, it is needed for all the subsequent access to the cursor
      cursor <- cursorResponse$id

      for(document in cursorResponse$result){
        documents[[document$`_key`]] <- aRango_document$new(connectionString, document)
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
          documents[[document$`_key`]] <- aRango_document$new(connectionString, document)
        }
      }

      return(documents)
    }
  ),

  private = list(
    connection = NULL,
    collectionName = NULL,
    collectionIdentifier = NULL,
    collectionGlobalUniqueId = NULL,
    collectionVertices = NULL,
    collectionCount = NULL,
    collectionStatus = NULL
  )
)
