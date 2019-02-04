library(jsonlite)
library(httr)
library(R6)

#' Returns all the graphs belonging to the giving database
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
graphs <- function(.database){
  graphsResults <- character()
  results <- NULL
  connectionString <- .database$.__enclos_env__$private$connectionStringRequest
  
  allGraphsResponse <- httr::GET(paste0(connectionString,"/_api/gharial/"))
  
  stop_for_status(allGraphsResponse)
  response <- content(allGraphsResponse)
  
  if(!is.null(response$graphs) && response$code == 200){
    results <- response$graphs
  }
  else{
    warning("Server didn't send the 'result' attribute")
  }
  
  # Iterate over the found results
  for(result in results){
    graphsResults <- c(graphsResults, result$`_key`)
  }
  
  # Returns the name of available collections
  return(graphsResults)  
}

#' The ArangoGraph class encapsulate the representation and the methods useful to manage
#' the retrieval, representation and updates of specific node and vertices belonging to Arango graph.
#'
#'
.aRango_graph <- R6Class (
  "ArangoGraph",
  
  public = list(
    
  ),
  
  private = list(
    
  )
)