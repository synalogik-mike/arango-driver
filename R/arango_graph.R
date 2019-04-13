#' Get all graphs
#' 
#' Returns all the graphs belonging to the giving database
#'
#' @param .database the AranagoDatabase handler
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
graphs <- function(.database){
  graphsResults <- character()
  results <- NULL
  connectionString <- .database$.__enclos_env__$private$connectionStringRequest
  
  allGraphsResponse <- httr::GET(paste0(connectionString,"/_api/gharial/"),
                                 add_headers(Authorization = .database$.__enclos_env__$private$auth))
  
  httr::stop_for_status(allGraphsResponse)
  response <- httr::content(allGraphsResponse)
  
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
arango_graph <- function(.database, name, createOnFail = FALSE){
  if(is.null(.database)){
    stop("Database is NULL, please provide a valid 'ArangoDatabase'")
  }
  
  if(class(.database)[1] != "ArangoDatabase"){
    stop("Only 'ArangoDatabase' objects can be processed by aRango::graph")
  }
  
  if(createOnFail){
    collectionInfoRequest <- paste0(.database$.__enclos_env__$private$connectionStringRequest, "/_api/gharial")
    
    # Waiting for version response
    response <- httr::POST(collectionInfoRequest, 
                           encode="json",
                           add_headers(Authorization = .database$.__enclos_env__$private$auth), 
                           body = list(name=name))
  }
  
  completeGraph <- .aRango_graph$new(.database$.__enclos_env__$private$connectionStringRequest, 
                                     name, 
                                     .database, auth = .database$.__enclos_env__$private$auth)
  
  return(completeGraph)
}


#' Edges insertion
#' 
#' Adds a set of edges to the given graph
#' 
#' @param .graph an ArangoGraph handler
#' @param listOfEdges a list containing the edges to be added in the graph
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
add_edges <- function(.graph, listOfEdges){
  
  # ==== Check on .graph variable ====
  if(is.null(.graph)){
    stop("Graph is NULL, please provide a valid 'ArangoGraph'")
  }
  
  if(class(.graph)[1] != "ArangoGraph"){
    stop("Only 'ArangoGraph' objects can be processed by aRango::add_elements")
  }
  
  # ==== TEMPORARY SOLUTION: which will be the final signature of this method? ====
  for(current in listOfEdges){
    addEdgeEndpoint <- paste0(.graph$.__enclos_env__$private$connectionStringRequest, "/edge/", current$collection)
    arangoServerResponse <- httr::POST(addEdgeEndpoint, 
                                       encode="json",
                                       add_headers(Authorization = .graph$.__enclos_env__$private$auth),
                                       body = current$edge)
    
    # TODO, how to manage?
    httr::stop_for_status(arangoServerResponse)
  }
  
  return(.graph)
}



#' Edges removal
#' 
#' Removes a collection of elements from the given graph.
#' 
#' @param .graph the graph affected by the deletion
#' @param listOfEdges a list of lists containing edges information
#'
#' @return the ArangoGraph object of the structure affected by the change
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
remove_edges <- function(.graph, listOfEdges){
  
  # ==== Check on .graph variable ====
  if(is.null(.graph)){
    stop("Graph is NULL, please provide a valid 'ArangoGraph'")
  }
  
  if(class(.graph)[1] != "ArangoGraph"){
    stop("Only 'ArangoGraph' objects can be processed by aRangodb::remove_edges")
  }
  
  # ==== TEMPORARY SOLUTION: which will be the final signature of this method? ====
  for(current in listOfEdges){
    currentCollection <- current$collection
    fromId <- current$edge$`_from`
    toId <- current$edge$`_to`
    
    edgeToRemove <- .graph$.__enclos_env__$private$currentDatabase %>%
      arango_collection(currentCollection) %>% 
      find_edge(fromId, toId)
    
    if(is.null(edgeToRemove)){
      # Fail?
      warning("edge not found")
    }
    else{
      deleteEdgeEndpoint <- paste0(.graph$.__enclos_env__$private$connectionStringRequest, "/edge/", edgeToRemove$getId())
      arangoServerResponse <- httr::DELETE(deleteEdgeEndpoint,
                                           add_headers(Authorization = .graph$.__enclos_env__$private$auth))
      
      # TODO, how to manage?
      httr::stop_for_status(arangoServerResponse)
    }
  }
  
  return(.graph)
}



#' Define new edges types
#' 
#' Adds an edge definition to this graph 
#' 
#' @param fromCollection an ArangoCollection or a string that indicates the type of "_from" document for the edge
#' @param relation a string that indicates the name of the edge to which add those collection _from/_to
#' @param toCollection an ArangoCollection or a string that indicates the type of "_to" document for the edge
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
define_edge <- function(.graph, fromCollection, relation, toCollection){
  
  # ==== Check on .graph variable ====
  if(is.null(.graph)){
    stop("Graph is NULL, please provide a valid 'ArangoGraph'")
  }
  
  if(class(.graph)[1] != "ArangoGraph"){
    stop("Only 'ArangoGraph' objects can be processed by aRango::define_edge")
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
  
  if(class(fromCollection)[1] == "ArangoCollection"){
    fromCollectionName <- fromCollection$getName()
  } else {
    fromCollectionName <- fromCollection
  }
  
  if(class(toCollection)[1] == "ArangoCollection"){
    toCollectionName <- toCollection$getName()
  } else {
    toCollectionName <- toCollection
  }
  
  # ==== Adding the edge to the graph on the server ====
  addEdgeDefinitionEndpoint <- paste0(.graph$.__enclos_env__$private$connectionStringRequest, "/edge")
  arangoServerResponse <- httr::POST(addEdgeDefinitionEndpoint, encode="json",
                                     add_headers(Authorization = .graph$.__enclos_env__$private$auth),
                                     body = list(from=list(fromCollectionName), to=list(toCollectionName), collection=relation))
  
  response <- httr::content(arangoServerResponse)
  
  # Edge already exist
  if(response$error == TRUE && response$errorNum == 1920){
    replaceEdgeDefinitionEndpoint <- paste0(.graph$.__enclos_env__$private$connectionStringRequest, "/edge/", relation)
    arangoServerResponse <- httr::PUT(replaceEdgeDefinitionEndpoint, 
                                      encode="json",
                                      add_headers(Authorization = .graph$.__enclos_env__$private$auth),
                                      body = list(
                                         from=list(unlist(.graph$.__enclos_env__$private$edges[[relation]]$from)), 
                                         to=list(unlist(.graph$.__enclos_env__$private$edges[[relation]]$to)), 
                                         collection=relation))
    
    # Remove old graph definition
    newGraph <- .aRango_graph$new(.graph$.__enclos_env__$private$connectionStringRequest, name,
                                  .graph$.__enclos_env__$private$currentDatabase,
                                  auth = .graph$.__enclos_env__$private$auth)
    rm(.graph)
    
    return(newGraph)
  }
  
  # ==== Adding on the server has been done correctly, now adding the edges into the structure ====
  # adding collections from/to into the list of vertices
  if(!(fromCollectionName %in% .graph$.__enclos_env__$private$vertices)){
    .graph$.__enclos_env__$private$vertices <- c(.graph$.__enclos_env__$private$vertices, fromCollectionName)
  }
  
  if(!(toCollectionName %in% .graph$.__enclos_env__$private$vertices)){
    .graph$.__enclos_env__$private$vertices <- c(.graph$.__enclos_env__$private$vertices, toCollectionName)
  }
  
  # if the relation still not exist it is added to the list of edges definition
  if(is.null(.graph$.__enclos_env__$private$edges[[relation]])){
    .graph$.__enclos_env__$private$edges[[relation]] <- list(from = c(), to = c())
  }
  
  if(!(fromCollectionName %in% .graph$.__enclos_env__$private$edges$relation$from)){
    .graph$.__enclos_env__$private$edges[[relation]]$from <- c(.graph$.__enclos_env__$private$edges[[relation]]$from, fromCollectionName)
  }
    
  if(!(toCollection %in% .graph$.__enclos_env__$private$edges$relation$to)){
    .graph$.__enclos_env__$private$edges[[relation]]$to <- c(.graph$.__enclos_env__$private$edges[[relation]]$to, toCollectionName)
  }
  
  return(.graph)
}




#' An ArangoGraph is a class where instances are used to handle the interaction with
#' real graphs on the server.
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
.aRango_graph <- R6::R6Class (
  "ArangoGraph",
  
  public = list(
    
    #' Creates a new graph from a one existing on the database
    #' 
    initialize = function(dbconnstring = NULL, name = NULL, db=NULL, auth=NULL) {
      
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
      private$currentDatabase <- db
      private$auth <- auth
      private$connectionStringRequest <- paste0(dbconnstring, "/_api/gharial/", name)
      graphInfoRequest <- paste0(private$connectionStringRequest)
      
      # Waiting for server response
      response <- httr::GET(graphInfoRequest,
                            add_headers(Authorization = private$auth))
      
      # Check response status
      if(status_code(response) == 404){
        stop(paste0("Graph ", name, " not found. Creates it on the server or call the 
                    aRango::arango_collection(name, createOnFail=TRUE, createOption = list(...))"))
      }
      
      graphInformation <- httr::content(response)$graph
      
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
        
        # Adding vertices references
        if(is.null(private$vertices)){
          private$vertices <- unlist(c(collectionEdgeName))
        }
        else{
          private$vertices <- unlist(c(private$vertices, collectionEdgeName))
        }
        
        # Adding edges references: only pair of collection (_from, _to)
        if(is.null(private$edges)){
          private$edges <- list()
        }
        
        private$edges[[collectionEdgeName]] <- list(from = c(collectionFromName), to = c(collectionToName))
        
        # Adding from and to collection iff not existing
        if(!(collectionFromName %in% private$vertices)){
          private$vertices <- unlist(c(private$vertices, collectionFromName))
        }
        
        if(!(collectionToName %in% private$vertices)){
          private$vertices <- unlist(c(private$vertices, collectionToName))
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
        
        if(!(orphan %in% private$vertices)){
          private$vertices <- unlist(c(private$vertices, orphan))
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
    
    #' Returns the orphan collections of the graph
    #'
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getOrphanCollections = function(){
      return(private$orphans)
    }
  ),
  
  private = list(
    name = NULL,
    vertices = c(),
    edges = list(),
    orphans = c(),
    id = NULL,
    revision = NULL,
    connectionStringDatabase = NULL,
    connectionStringRequest = NULL,
    currentDatabase = NULL,
    auth = NULL
  )
)