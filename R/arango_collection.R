library(jsonlite)
library(httr)
library(R6)

#' Returns all the collections belonging to the giving database
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
collections <- function(.database, includeSystem=FALSE){
  collectionResults <- character()
  results <- NULL
  connectionString <- .database$.__enclos_env__$private$connectionStringRequest
  
  allCollectionsResponse <- httr::GET(paste0(connectionString,"/_api/collection/"))
  
  stop_for_status(allCollectionsResponse)
  response <- content(allCollectionsResponse)
  
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



#' An ArangoConnection is a class that contains and manages a collection belonging to a database 
#' in a server.
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
.aRango_collection <- R6Class (
  "ArangoCollection",
  
  public = list(
    #' Creates a new collection belonging to an existing database in the server
    #'
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    initialize = function(database) {
      
    }
  ),
  
  private = list(
    
  )
)