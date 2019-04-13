#' Get all collections name
#'
#' Returns all the collections contained in the given database
#'
#' @param .element a valid ArangoDatabase object
#' @param includeSystem if TRUE include the system databases (default FALSE)
#' 
#' @return a character vector with all the collections contained in the given database
#' 
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
collections <- function(.database, includeSystem=FALSE){
  collectionResults <- character()
  results <- NULL
  connectionString <- .database$.__enclos_env__$private$connectionStringRequest
  
  allCollectionsResponse <- httr::GET(
    paste0(connectionString,"/_api/collection/"),
    add_headers(Authorization = .database$.__enclos_env__$private$auth)
  )
  
  httr::stop_for_status(allCollectionsResponse)
  response <- httr::content(allCollectionsResponse)
  
  if(!is.null(response$result)){
    results <- response$result
  }
  else{
    warning("Server didn't send the 'result' attribute")
  }
  
  # Iterate over the found results
  for(result in results){
    if(!result$isSystem){
      collectionResults <- c(collectionResults, result$name)
    }
  }
  
  # Returns the name of available collections
  return(collectionResults)  
}



#' Get or create a collection
#' 
#' Return an object representing the collection with the given name into the specified the database:
#' the object must be used to handle requests to the collection.
#'
#' @param .element a valid ArangoDatabase object
#' @param name the name of the collection
#' @param createOnFail if the collection were not found creates it (default FALSE)
#' 
#' @return an object representing the collection with the given name
#' 
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
arango_collection <- function(.database, name, createOnFail=FALSE){
  if(is.null(.database)){
    stop("Database is NULL, please provide a valid 'ArangoDatabase'")
  }
  
  if(class(.database)[1] != "ArangoDatabase"){
    stop("Only 'ArangoDatabase' objects can be processed by aRango::arango_collection")
  }
  
  # If createOnFail first trying to create the collection: if a collection with same name
  # exists the server returns the code 409 'duplicate name'
  if(createOnFail){
    collectionInfoRequest <- paste0(.database$.__enclos_env__$private$connectionStringRequest, "/_api/collection/")
    
    # Waiting for version response
    response <- httr::POST(
      collectionInfoRequest, 
      add_headers(Authorization = .database$.__enclos_env__$private$auth),
      encode="json", 
      body = list(name=name))
  }
  
  db <- .aRango_collection$new(.database, name, .database$.__enclos_env__$private$auth)
  
  return(db)
}



#' An ArangoCollection is a class where instances are used to handle the interaction with
#' real collections on the server.
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
.aRango_collection <- R6::R6Class (
  "ArangoCollection",
  
  public = list(
    
    #' Creates a new collection belonging to an existing database in the server
    #'
    #' @param name the name of the collection
    #' @param waitForSync (from Arango doc) if true then the data is synchronized to disk before returning from a 
    #'                    document create, update, replace or removal.
    #' @param isSystem (from Arango doc) if true creates a system collection. In this case name SHOULD start 
    #'                 with an underscore
    #' @param type (from Arango doc) the type of the collection to create. The following values are valid,
    #'             collection_type$DOCUMENT or collection_type$EDGE
    #'            
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    initialize = function(database, name, auth, waitForSync = FALSE, isSystem = FALSE, type = collection_type$DOCUMENT) {
      if(is.null(database)){
        stop("Database is NULL, please provide a valid 'ArangoDatabase'")
      }
      
      if(class(database)[1] != "ArangoDatabase"){
        stop("Only 'ArangoDatabase' objects can be processed by the class ArangoCollection")
      }
      
      if(is.null(name)){
        stop("name is NULL, please provide a valid collection name")
      }
      
      private$auth <- auth
      private$connectionStringDatabase <- database$.__enclos_env__$private$connectionStringRequest
      private$connectionStringRequest <- paste0(database$.__enclos_env__$private$connectionStringRequest, "/_api/collection/", name)
      collectionInfoRequest <- paste0(private$connectionStringRequest)
      
      # Waiting for server response
      response <- httr::GET(
        collectionInfoRequest,
        add_headers(Authorization = private$auth)
      )
      
      # Check response status
      if(status_code(response) == 404){
        stop(paste0("Collection ", name, " not found. Creates it on the server or call the 
                    aRango::arango_collection(name, createOnFail=TRUE, createOption = list(...))"))
      }
      
      # Response is ok, fill the internal state
      collectionInformation <- httr::content(response)
      private$collname <- name
      private$isSystem <- collectionInformation$isSystem
      private$id <- collectionInformation$id
      private$type <- collectionInformation$type
      private$status <- collectionInformation$status
    },
    
    #' Returns the name of the collection handled by this object
    #' 
    #' @return the name of the collection handled by this object
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getName = function(){
      return(private$collname)
    },
    
    #' Returns TRUE iff this object handles a system collection, FALSE otherwise
    #' 
    #' @return TRUE iff this object handles a system collection, FALSE otherwise
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    isSystemCollection = function(){
      return(private$isSystem)
    },
    
    #' Returns the identifier of the collection
    #' 
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getId = function(){
      return(private$id)
    },
    
    #' Returns the status of the collection
    #' 
    #' @seealso collection_status enumeration
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getStatus = function(){
      return(private$status)
    },
    
    #' Returns the number of the element of this collection
    #' 
    #' @return the number of the element of this collection
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getCount = function(){
      count <- 0
      
      countRequest <- paste0(private$connectionStringRequest, "/count")
      countResponse <- httr::GET(
        countRequest,
        add_headers(Authorization = private$auth)
      )
      
      # Check response status
      if(httr::status_code(countResponse) == 404){
        stop(paste0("Collection ", name, " not found. The collection has been deleted?"))
      }
      
      # Response is ok, fill the internal state
      countInfo <- httr::content(countResponse)
      
      return(countInfo$count)
    },
    
    #' Returns the type of the collection
    #' 
    #' @seealso collection_type enumeration
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getType = function(){
      return(private$type)
    }
  ),
  
  private = list(
    collname = NULL,
    connectionStringRequest = NULL,
    connectionStringDatabase = NULL,
    isSystem = FALSE,
    id = NULL,
    type = NULL,
    status = NULL,
    auth = NULL
  )
)