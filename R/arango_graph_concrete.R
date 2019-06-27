#' Traversal of a graph
#' 
#' Execute the traversal of a graph OR starting from a given set of edges
#' 
#' @param vertices a collection of vertices (or vertices' keys) which represent the starting point of the traversal
#' @param depth how many edges traverse from each starting vertex
#' @param direction from each starting vertex the type of edges to traverse. Must be one between {"ANY", "INBOUND", OUTBOUND}
#' @param edges the edge collection names to use during the traverse. If not given traverse on any existing edge
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
traversal <- function(.graph, vertices, depth=1, direction="ANY", edges=NULL){
  
  # ==== Check on .graph variable ====
  if(is.null(.graph)){
    stop("Graph is NULL, please provide a valid 'ArangoGraph'")
  }
  
  if(class(.graph)[1] != "ArangoGraph"){
    stop("Only 'ArangoGraph' objects can be processed by aRango::traversal")
  }
  
  # ==== Check parameters ====
  # direction must be one between {"ANY","INBOUND","OUTBOUND"}
  if(direction != "ANY" && direction != "INBOUND" && direction != "OUTBOUND"){
    stop(paste0("Direction of traversal can be only one of {'ANY','INBOUND','OUTBOUND'} given: ",direction))
  }
  
  # vertices must be a vector of documents or strings containing the starting vertices 
  for(start in vertices){
    if(class(start)[1] != "ArangoDocument" && class(start)[1] != "character"){
      stop("Starting vertices can be only ArangoDocument or strings containing the _id of the starting node")
    }
  }
  
  # ==== Preparing the AQL query ====
  firstStartVertex <- TRUE
  startVertexList <- NULL
  
  for(start in vertices){
    if(class(start)[1] == "ArangoDocument"){
      if(firstStartVertex){
        startVertexList <- paste0("'", start$getId(), "'")
        firstStartVertex <- FALSE
      }
      else{
        startVertexList <- paste0(startVertexList,",","'", start$getId(), "'")
      }
    }
    
    if(class(start)[1] == "character"){
      if(firstStartVertex){
        startVertexList <- paste0("'", start, "'")
        firstStartVertex <- FALSE
      }
      else{
        startVertexList <- paste0(startVertexList,",","'", start, "'")
      }
    }
  }
  
  if(is.null(edges)){
    subgraphQuery <- paste0("FOR startVertex IN [", startVertexList,"] ",
                            "FOR v,e,p IN 1..", depth," ", direction," startVertex GRAPH '", .graph$getName(),"' ",
                            "RETURN p")
  }
  else{
    edgeNames <- ""
    firstEdge <- TRUE
    for(edgeCollection in edges){
      if(firstEdge){
        edgeNames <- edgeCollection
        firstEdge <- FALSE
      }
      else
      {
        edgeNames <- paste0(edgeNames,", ", edgeCollection)
      }
    }
    
    subgraphQuery <- paste0("FOR startVertex IN [", startVertexList,"] ",
                            "FOR v,e,p IN 1..", depth," ", direction," startVertex ", edgeNames," ",
                            "RETURN p")
  }

  getSubgraph <- .graph$.__enclos_env__$private$currentDatabase %>% aql(subgraphQuery)
  subgraphElements <- getSubgraph()
  
  # Fourth, create collect the results and return the graph
  edgeSet <- list()
  vertexSet <- list()
  uniqueRelations <- NULL
  firstElement <- TRUE
  
  for(path in subgraphElements){
    
    for(edge in path$edges){
      if(firstElement){
        uniqueRelations <- c(strsplit(edge$"_id", "/")[[1]][1])
        firstElement <- FALSE
      }
      else{
        uniqueRelations <- c(uniqueRelations, strsplit(edge$"_id", "/")[[1]][1])
      }
      
      # Edge of the path
      edgeSet[[edge$"_id"]] <- edge
    }
    
    for(vertex in path$vertices){
      # Vertices of the path
      vertexSet[[vertex$"_id"]] <- vertex
    }
  }
  
  return(.aRango_graph_concrete$new(vertexSet = vertexSet, edgeSet = edgeSet, uniqueRelations = unique(uniqueRelations)))
}


#' Get complete graph
#' 
#' Returns the graph vertices and edges for the given ArangoGraph (BE CAREFUL, the grap may
#'  contains lot of elements)
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
all_graph <- function(.graph){
  
  # ==== Check on .graph variable ====
  if(is.null(.graph)){
    stop("Graph is NULL, please provide a valid 'ArangoGraph'")
  }
  
  if(class(.graph)[1] != "ArangoGraph"){
    stop("Only 'ArangoGraph' objects can be processed by aRango::all_graph")
  }
  
  allCollections <- ""
  firstCollection <- TRUE
  
  # First, create the search for all vertices
  for(collectionName in .graph$.__enclos_env__$private$vertices){
    if(firstCollection){
      allCollections <- paste0("(FOR v IN ", collectionName, " RETURN v)")
      firstCollection <- FALSE
    }
    else{
      allCollections <- paste0(allCollections, paste0(", (FOR v IN ", collectionName, " RETURN v)"))
    }
  }
  
  allCollections <- paste0("UNION(", allCollections, ")")
  
  # Second, create the whole query
  wholeGraphAql <- paste0("FOR element IN UNION(", 
                          "( FOR vertex IN ", allCollections, " ",
                          "FOR v, e, p IN OUTBOUND vertex GRAPH '",.graph$getName(),"' ",
                          "RETURN e),",
                          "( FOR vertex IN ", allCollections, " ",
                          "RETURN vertex)) ",
                          "RETURN element")
  
  # Third, create query and execute the retrieval of the objects
  getAllGraphElements <- .graph$.__enclos_env__$private$currentDatabase %>% aql(wholeGraphAql)
  allElements <- getAllGraphElements()
  
  # Fourth, create collect the results and return the graph
  edgeSet <- list()
  vertexSet <- list()
  uniqueRelations <- NULL
  
  for(element in allElements){
    keys <- names(element)
    if("_from" %in% keys && "_to" %in% keys){
      # Management of the edge
      edgeSet[[element$"_id"]] <- element
    }
    else{
      # Management of the vertex
      vertexSet[[element$"_id"]] <- element
    }
  }
  
  return(.aRango_graph_concrete$new(vertexSet = vertexSet, edgeSet = edgeSet, uniqueRelations = names(.graph$getEdgeDefinitions())))
}


#' The ArangoGraph class encapsulate the representation and the methods useful to manage
#' the retrieval, representation and updates of specific node and vertices belonging to Arango graph.
#'
.aRango_graph_concrete <- R6::R6Class (
  "ArangoGraphConcrete",
  
  public = list(
    
    initialize = function(vertexSet = NULL, edgeSet = NULL, uniqueRelations = NULL){
      # TODO: up to now the vertexSet and the edgeSet are lists, while the next step is to have them as documents
      # better if they come from the same repository
      private$vertices <- vertexSet
      private$edges <- edgeSet
      private$relations <- uniqueRelations
    },
    
    #' Returns a tensor that contains, for each relation between the vertices, an adjacency matrix
    #' for that relation. The third dimension of the tensor is then the one regarding the relation.
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
    getAdjacencyTensor = function(){
      tensor <- list()
      vertexNames <- unique(unlist(sapply(private$vertices, function(v){return(v$"_id")})))
      
      for(relation in private$relations){
        tensor[[relation]] <- matrix(0, length(private$vertices), length(private$vertices))
        colnames(tensor[[relation]]) <- vertexNames
        rownames(tensor[[relation]]) <- vertexNames
      }
      
      # Fill the tensor
      private$edges %>% purrr::walk(function(e){ tensor[[strsplit(e$"_id", "/")[[1]][1]]][e$"_from", e$"_to"] <<- 1 })
      
      return(tensor)
    },
    
    #' Returns a boolean value telling whether the graph is empty or not
    isEmpty = function(){
      return(length(private$vertices) == 0)
    }
  ),
  
  private = list(
    vertices = NULL,
    edges = NULL,
    relations = NULL
  )
)