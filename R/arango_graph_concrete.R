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
