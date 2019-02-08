library(jsonlite)
library(httr)
library(R6)
library(magrittr)

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
#' @param name the name of the graph
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
  
  completeGraph <- .aRango_graph$new(.database$.__enclos_env__$private$connectionStringRequest, name)
  
  return(completeGraph)
}



#' Adds an edge definition to this graph 
#' 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
edge_definition <- function(.graph, fromCollection, relation, toCollection){
  
  # ==== Check on .graph variable ====
  if(is.null(.graph)){
    stop("Graph is NULL, please provide a valid 'ArangoGraph'")
  }
  
  if(class(.graph)[1] != "ArangoGraph"){
    stop("Only 'ArangoGraph' objects can be processed by aRango::edge_definition")
  }
  
  # ==== Check on from/to variable ====
  if(is.null(fromCollection) || is.null(relation) || is.null(toCollection)){
    stop("One of the parameters is null")
  }
  
  if(class(fromCollection)[1] != "ArangoCollection" && class(fromCollection)[1] != "character"){
    stop("'from' parameter must be a valid collection or a string")
  }
  
  if(class(toCollection)[1] != "ArangoCollection" && class(toCollection)[1] != "character"){
    stop("'to' parameter must be a valid collection or a string")
  }
  
  if(class(relation)[1] != "character"){
    stop("'to' parameter must be a valid collection or a string")
  }
  
  # ==== Adding the edge to the graph on the server ====
  addEdgeDefinitionEndpoint <- paste0(.graph$.__enclos_env__$private$connectionStringRequest, "/edge")
  arangoServerResponse <- httr::POST(addEdgeDefinitionEndpoint, encode="json", 
                                     body = list(from=list(fromCollection), to=list(toCollection), collection=relation))
  
  response <- content(arangoServerResponse)
  
  # Edge already exist
  if(response$error == TRUE && response$errorNum == 1920){
    replaceEdgeDefinitionEndpoint <- paste0(.graph$.__enclos_env__$private$connectionStringRequest, "/edge/", relation)
    arangoServerResponse <- httr::PUT(replaceEdgeDefinitionEndpoint, encode="json", 
                                       body = list(
                                         from=list(unlist(.graph$.__enclos_env__$private$edges[[relation]]$from)), 
                                         to=list(unlist(.graph$.__enclos_env__$private$edges[[relation]]$to)), 
                                         collection=relation))
    
    # Remove old graph definition
    newGraph <- .aRango_graph$new(.graph$.__enclos_env__$private$connectionStringRequest, name)
    rm(.graph)
    
    return(newGraph)
  }
  
  # ==== Adding on the server has been done correctly, now adding the edges into the structure ====
  # adding collections from/to into the list of verticies
  if(!(fromCollection %in% .graph$.__enclos_env__$private$verticies)){
    .graph$.__enclos_env__$private$verticies <- c(.graph$.__enclos_env__$private$verticies, fromCollection)
  }
  
  if(!(toCollection %in% .graph$.__enclos_env__$private$verticies)){
    .graph$.__enclos_env__$private$verticies <- c(.graph$.__enclos_env__$private$verticies, toCollection)
  }
  
  # if the relation still not exist it is added to the list of edges definition
  if(is.null(.graph$.__enclos_env__$private$edges[[relation]])){
    .graph$.__enclos_env__$private$edges[[relation]] <- list(from = c(), to = c())
  }
  
  if(!(fromCollection %in% .graph$.__enclos_env__$private$edges$relation$from)){
    .graph$.__enclos_env__$private$edges[[relation]]$from <- c(.graph$.__enclos_env__$private$edges[[relation]]$from, fromCollection)
  }
    
  if(!(toCollection %in% .graph$.__enclos_env__$private$edges$relation$to)){
    .graph$.__enclos_env__$private$edges[[relation]]$to <- c(.graph$.__enclos_env__$private$edges[[relation]]$to, toCollection)
  }
  
  return(.graph)
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
    initialize = function(dbconnstring = NULL, name = NULL) {
      
      if(is.null(dbconnstring)){
        stop("please provide a valid database connection string")
      }
      
      if(class(dbconnstring)[1] != "character"){
        stop("please provide a valid string for database connection")
      }
      
      if(is.null(name)){
        stop("name is NULL, please provide a valid collection name")
      }
      
      private$connectionStringDatabase <- dbconnstring
      private$connectionStringRequest <- paste0(dbconnstring, "/_api/gharial/", name)
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
          private$verticies <- unlist(c(collectionEdgeName))
        }
        else{
          private$verticies <- unlist(c(private$verticies, collectionEdgeName))
        }
        
        # Adding edges references: only pair of collection (_from, _to)
        if(is.null(private$edges)){
          private$edges <- list()
        }
        
        private$edges[[collectionEdgeName]] <- list(from = c(collectionFromName), to = c(collectionToName))
        
        # Adding from and to collection iff not existing
        if(!(collectionFromName %in% private$verticies)){
          private$verticies <- unlist(c(private$verticies, collectionFromName))
        }
        
        if(!(collectionToName %in% private$verticies)){
          private$verticies <- unlist(c(private$verticies, collectionToName))
        }
      }
      
      # Save all the orphan collections
      for(orphan in graphInformation$orphanCollections){
        if(is.null(private$orphans))
        {
          private$orphans <- unlist(c(orphan))
        }
        else{
          private$orphans <- unlist(c(private$orphans, orphan))
        }
        
        if(!(orphan %in% private$verticies)){
          private$verticies <- unlist(c(private$verticies, orphan))
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
    },
    
    #' Returns the edges definition of the graph
    #'
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getEdgeDefinitions = function(){
      return(private$edges)
    },
    
    getOrphanCollections = function(){
      return(private$orphans)
    }
  ),
  
  private = list(
    name = NULL,
    verticies = c(),
    edges = list(),
    orphans = c(),
    id = NULL,
    revision = NULL,
    connectionStringDatabase = NULL,
    connectionStringRequest = NULL
  )
)