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



#' Returns the graph identified with the given name
#' 
#' @param name the nae of the graph
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
graph <- function(.database, name, createOnFail = FALSE){
  if(is.null(.database)){
    stop("Database is NULL, please provide a valid 'ArangoDatabase'")
  }
  
  if(class(.database)[1] != "ArangoDatabase"){
    stop("Only 'ArangoDatabase' objects can be processed by aRango::graph")
  }
  
  if(createOnFail){
    collectionInfoRequest <- paste0(.database$.__enclos_env__$private$connectionStringRequest, "/_api/gharial")
    
    # Waiting for version response
    response <- httr::POST(collectionInfoRequest, encode="json", body = list(name=name))
  }
  
  completeGraph <- .aRango_graph$new(.database, name)
  
  return(completeGraph)
}



#' The ArangoGraph class encapsulate the representation and the methods useful to manage
#' the retrieval, representation and updates of specific node and vertices belonging to Arango graph.
#'
.aRango_subgraph <- R6Class (
  "ArangoSubgraphGraph",
  
  public = list(
    
    initialize = function(vertexSet = NULL, edgeSet = NULL){
      
    },
    
    #' Returns a list of matrices that contains, for each relation between the nodes, an adjacency matrix
    #' for that relation.
    #' For example, given "a" -friend_of-> "b", "c" -spouse-> "b" the results will be:
    #' 
    #'                a   b   c
    #'             a  0   1   0
    #' friend_of = b  0   0   0
    #'             c  0   0   0
    #'             
    #'                a   b   c
    #'             a  0   0   0
    #' spouse    = b  0   0   0
    #'             c  0   1   0             
    #' 
    #' If "complete" option is set to TRUE the content of the matrix will be the edge key within the ArangoDB
    #' server: looking to the previous example
    #' 
    #'                a         b         c
    #'             a  0   friend_of/112   0
    #' friend_of = b  0         0         0
    #'             c  0         0         0
    #'             
    #'                a        b       c
    #'             a  0        0       0
    #' spouse    = b  0        0       0
    #'             c  0   spouse/231   0
    #'
    getAdjacencyTensor = function(complete=FALSE){
      
    }
  ),
  
  private = list(
    vertices = NULL,
    edges = NULL
  )
)

#' The ArangoGraph class encapsulate the representation and the methods useful to manage
#' the retrieval, representation and updates of specific node and vertices belonging to Arango graph.
#'
.aRango_graph <- R6Class (
  "ArangoGraph",
  
  public = list(
    
    #' Creates a new graph from a one existing on the database
    #' 
    initialize = function(database = NULL, name = NULL) {
      if(is.null(database)){
        stop("Database is NULL, please provide a valid 'ArangoDatabase'")
      }
      
      if(class(database)[1] != "ArangoDatabase"){
        stop("Only 'ArangoDatabase' objects can be processed by the class ArangoCollection")
      }
      
      if(is.null(name)){
        stop("name is NULL, please provide a valid collection name")
      }
      
      private$connectionStringDatabase <- database$.__enclos_env__$private$connectionStringRequest
      private$connectionStringRequest <- paste0(database$.__enclos_env__$private$connectionStringRequest, "/_api/gharial/", name)
      graphInfoRequest <- paste0(private$connectionStringRequest)
      
      # Waiting for server response
      response <- httr::GET(graphInfoRequest)
      
      # Check response status
      if(status_code(response) == 404){
        stop(paste0("Graph ", name, " not found. Creates it on the server or call the 
                    aRango::collection(name, createOnFail=TRUE, createOption = list(...))"))
      }
      
      graphInformation <- content(response)$graph
      
      # Save all the edges that has been retrieved
      for(edge in graphInformation$edgeDefinitions){
        
        collectionEdgeName <- edge$collection
        collectionFromName <- edge$from[1]
        collectionToName <- edge$to[1]
        
        # TODO: at the moment the only edges managed are the ones from ONE collection to ANOTHER ONE
        if(length(edge$from) > 1 || length(edge$to) > 1){
          warning(paste0("edge '",collectionEdgeName,"' manages multiple collections in the _from or _to collection set. 
                         The only ones taken into account will be the first listed, 
                         '", collectionFromName,"' -> '",collectionToName,"'."))
        }
        
        # Adding verticies references
        if(is.null(private$verticies)){
          private$verticies <- c(collectionEdgeName)
        }
        else{
          private$verticies <- c(private$verticies, collectionEdgeName)
        }
        
        # Adding edges references: only pair of collection (_from, _to)
        if(is.null(private$edges)){
          private$edges <- list()
        }
        
        private$edges[[collectionEdgeName]] <- c(collectionFromName, collectionToName)
      }
      
      # Save all the orphan collections
      for(orphan in graphInformation$orphanCollections){
        if(is.null(private$orphans))
        {
          private$orphans <- c(orphan)
        }
        else{
          private$orphans <- c(private$orphans, orphan)
        }
      }
      
      private$id <- graphInformation$"_id"
      private$revision <- graphInformation$"_rev"
      private$name <- graphInformation$name
    },
    
    #' Returns the name of the graph
    #'
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getName = function(){
      return(private$name)
    }, 
    
    #' Returns the identifier of the graph
    #'
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getId = function(){
      return(private$id)
    },
    
    #' Returns the current revision of the graph
    #'
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getRevision = function(){
      return(private$revision)
    }
  ),
  
  private = list(
    name = NULL,
    verticies = NULL,
    edges = NULL,
    orphans = NULL,
    id = NULL,
    revision = NULL,
    connectionStringDatabase = NULL,
    connectionStringRequest = NULL
  )
)