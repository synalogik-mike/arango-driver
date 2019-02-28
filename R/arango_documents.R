.check_numeric_value <- function(value){
  if(!is.numeric(value)){
    stop("the value must be numeric")
  }
  return(value)
}

#' Get all documents
#' 
#' Returns all the documents belonging to the given collection
#'
#' @return all the documents belonging to the given collection
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
all_documents <- function(.collection){
  
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
  cursorResponse <- httr::content(collectionBatch)
  
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
    cursorResponse <- httr::content(collectionBatch)
    
    if(cursorResponse$code != "200" && cursorResponse$code != "201" ){
      stop("Something were wrong during the retrieval of the documents of this collection (arango cursor not created)")
    }
    
    for(document in cursorResponse$result){
      documents[[document$`_key`]] <- .aRango_document$new(document, connectionString)
    }
  }
  
  return(documents)
}



#' Create new documents
#' 
#' Creates a new document of this collection and returns it
#'
#' @param .collection the ArangoCollection that handles the collection to be updated
#' @param key the key that will be used as unique identifier within the collection for the new document
#' 
#' @return an ArangoDocument representing the new document data         
#'     
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
document_insert <- function(.collection, key){
  
  if(class(.collection)[1] != "ArangoCollection"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::document_insert function")
  }
  
  # Creates the cursor and iterate over it to retrieve the entire collection
  connectionString <- .collection$.__enclos_env__$private$connectionStringDatabase
  insertionResult <- httr::POST(paste0(connectionString,"/_api/document/", .collection$getName(), "?returnNew=true"),
                                body = list(`_key`=key),
                                encode = "json")
  insertionResponse <- httr::content(insertionResult)
  
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



#' Update a document
#' 
#' Updates the attributes of the given document. When it is needed to made effective
#' the updates must be call the collection_update() function.
#'
#' @param .data the document to be updated
#' @param ... new or updated assignment to be added to the given document
#' 
#' @return the ArangoDocument updated but not yet consistent with the server image
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
document_set <- function(.data, ...){
  
  if(class(.data)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::document_set function")
  }
  
  arguments <- list(...)
  
  for(key in names(arguments)){
    value <- arguments[[key]]
    
    .data$.__enclos_env__$private$documentValues[[key]] <- value
  }
  
  return(.data)
}



#' Remove documents' properties
#' 
#' Remove the assigments for the key passed as argument from the given document. 
#' When it is needed to made effective the updates must be call the collection_update() function.
#'
#' @param .data the document to be updated
#' @param ... keys to be removed from the given document
#' 
#' @return the ArangoDocument updated but not yet consistent with the server image
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
document_unset <- function(.data, ...){
  
  if(class(.data)[1] != "ArangoDocument"){
    stop("Only 'ArangoDocument' objects can be processed by aRango::document_unset function")
  }
  
  variableToRemove <- c(...)
  
  for(key in variableToRemove){
    .data$.__enclos_env__$private$documentValues[[key]] <- NULL
  }
  
  return(.data)
}



#' Execute document updates
#' 
#' Excecutes the update of a document on the server
#'
#' @param the ArangoDocument to be updated on the server
#'
#' @return the ArangoDocument updated but not yet consistent with the server image
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
collection_update <- function(.data){
  
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
  updatedObjectInfo <- httr::content(updateResult)
  .data$.__enclos_env__$private$currentRevision <- updatedObjectInfo$`_rev`
  
  return(.data)
}

#' Find edge document
#' 
#' Returns the edge in this collection connecting the documents passed as argument, if any.
#' 
#' @param .collection the ArangoCollection that handles the collection
#' @param from the document id ("collection/key") that represents the _from vertex
#' @param to the document id ("collection/key") that represents the _to vertex 
#'
#' @return the document representing the edge between the given documents
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
find_edge <- function(.collection, from, to){
  
  if(class(.collection)[1] != "ArangoCollection"){
    stop("Only 'ArangoCollection' objects can be processed by aRango::find_edge function")
  }

  if(.collection$getType() != collection_type$EDGE){
    stop("Edges can be searched only within EDGES collection, the given one is a DOCUMENT collection")
  }
    
  if(class(from)[1] == "ArangoDocument" && class(to)[1] == "ArangoDocument"){
    foundEdge <- .collection %>% collection_filter(`_from`=from$getId(), `_to`=to$getId())
    
    if(length(foundEdge) > 0){
      return(foundEdge[[1]])
    }
  }
  else if(class(from)[1] == "character" && class(to)[1] == "character"){
    foundEdge <- .collection %>% 
      collection_filter(`_from`=from, `_to`=to)
    
    if(length(foundEdge) > 0){
      return(foundEdge[[1]])
    }
  }
  else{
    return(NULL) 
  }
}

#' Filter documents
#' 
#' Filters the documents from a collection
#'
#' @param .collection the ArangoCollection that handles the collection
#' @param ... a list of assigment, will be translated as "id==val", or comparison
#' filters given using the \%gt\%, \%lt\%, \%geq\%, \%leq\% operators.
#' 
#' @return the documents that matches the given filters
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
collection_filter <- function(.collection, ...){
  
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
    cursorResponse <- httr::content(collectionBatch)
    
    if(cursorResponse$code != "200" && cursorResponse$code != "201" ){
      stop("Something were wrong during the retrieval of the documents of this collection (arango cursor not created)")
    }
    
    for(document in cursorResponse$result){
      documents[[document$`_key`]] <- .aRango_document$new(document, connectionString)
    }
  }
  
  return(documents)
}



#' Delete document
#' 
#' Deletes the given document
#'
#' @param .document the ArangoDocument to be removed from the collection
#'
#' @return TRUE iff the document has been removed from the collection
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
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



#' An ArangoDocument contains the data regarding a document that belongs to some
#' collection in the Arango Server instance. The object allows the user to get/set
#' and find other information regarding the document in the server.
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
.aRango_document <- R6::R6Class (
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
    
    #' Returns the name of the collection to which the document belongs
    #' 
    #' @return the name of the collection to which the document belongs
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getCollection = function(){
      return(private$originalCollection)
    },
    
    #' Returns the id of the document ("collection/key")
    #' 
    #' @return the id of the document ("collection/key")
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getId = function(){
      return(paste0(private$originalCollection,"/",private$documentId))
    },
    
    #' Returns the key of the document
    #' 
    #' @return the key of the document
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getKey = function(){
      return(private$documentId)
    },
    
    #' Returns the current revision of the document
    #' 
    #' @return the current revision of the document
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getRevision = function(){
      return(private$currentRevision)
    },
    
    #' Returns a list containing the key-values of the document
    #' 
    #' @return a list containing the key-values of the document
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getValues = function(){
      return(private$documentValues)
    },
    
    #' Returns a character vector containing the available keys for this document
    #' 
    #' @return a character vector containing the available keys for this document
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getKeys = function(){
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