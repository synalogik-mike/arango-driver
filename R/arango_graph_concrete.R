library(jsonlite)
library(httr)
library(R6)
library(magrittr)
library(purrr)

#' Get complete graph
#' 
#' Returns the graph vertices and edges for the given ArangoGraph (BE CAREFUL, the grap may
#'  contains lot of elements)
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
connections <- function(.graph){
  
  # ==== Check on .graph variable ====
  if(is.null(.graph)){
    stop("Graph is NULL, please provide a valid 'ArangoGraph'")
  }
  
  if(class(.graph)[1] != "ArangoGraph"){
    stop("Only 'ArangoGraph' objects can be processed by aRango::edge_definition")
  }
  
  allCollections <- ""
  firstCollection <- TRUE
  
  # First, create the search for all verticies
  for(collectionName in .graph$.__enclos_env__$private$verticies){
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
.aRango_graph_concrete <- R6Class (
  "ArangoGraphConcrete",
  
  public = list(
    
    initialize = function(vertexSet = NULL, edgeSet = NULL, uniqueRelations = NULL){
      # TODO: up to now the vertexSet and the edgeSet are lists, while the next step is to have them as documents
      # better if they come from the same repository
      private$verticies <- vertexSet
      private$edges <- edgeSet
      private$relations <- uniqueRelations
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
      tensor <- list()
      vertexNames <- unique(unlist(sapply(private$verticies, function(v){return(v$"_id")})))
      
      for(relation in private$relations){
        tensor[[relation]] <- matrix(0, length(private$verticies), length(private$verticies))
        colnames(tensor[[relation]]) <- vertexNames
        rownames(tensor[[relation]]) <- vertexNames
      }
      
      # Fill the tensor
      private$edges %>% walk(function(e){ tensor[[strsplit(e$"_id", "/")[[1]][1]]][e$"_from", e$"_to"] <<- 1 })
      
      return(tensor)
    }
  ),
  
  private = list(
    verticies = NULL,
    edges = NULL,
    relations = NULL
  )
)