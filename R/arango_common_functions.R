# =========================================================================================
# COMMON FUNCTIONS, i.e. set of functions that have the same signature in different context
# =========================================================================================

#' Drop an existing database, graph or collection
#'
#' @param .element can be an ArangoDatabase or an ArangoCollection or an ArangoGraph
#' 
#' @return TRUE iff the element has been deleted, FALSE otherwise
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
drop <- function(.element){
  if(is.null(.element)){
    stop("Database or Collection is NULL, please provide a valid 'ArangoDatabase'/'ArangoCollection'/'ArangoGraph'")
  }
  
  if(class(.element)[1] == "ArangoDatabase"){
    return(.drop_database(.element))
  }
  else if(class(.element)[1] == "ArangoCollection"){
    return(.drop_collection(.element))
  }
  else if(class(.element)[1] == "ArangoGraph"){
    return(.drop_graph(.element))
  }
  else{
    stop("Only 'ArangoDatabase' or 'ArangoCollection' or 'ArangoGraph' objects can be 
          processed by aRango::drop")
  }
  
  return(FALSE)
}

#' Internal function for collection removal
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl 
.drop_collection <- function(.element){
  collectionRequest <- .element$.__enclos_env__$private$connectionStringRequest
  response <- httr::DELETE(collectionRequest)
  
  if(status_code(response) == 400){
    stop("Request is invalid")
  }
  
  if(status_code(response) == 404){
    stop(paste0("Collection cannot be found in the server"))
  }
  
  return(TRUE)
}


#' Internal function for graph removal
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl 
.drop_graph <- function(.element){
  graphRequest <- .element$.__enclos_env__$private$connectionStringRequest
  response <- httr::DELETE(graphRequest)
  
  if(status_code(response) == 400){
    stop("Request is invalid")
  }
  
  if(status_code(response) == 404){
    stop(paste0("Graph cannot be found in the server"))
  }
  
  return(TRUE)
}


#' Internal function for database removal
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl 
.drop_database <- function(.element){
  dbPrefixReq <- .element$.__enclos_env__$private$originalConnection
  response <- httr::DELETE(paste0(dbPrefixReq,"/_api/database/", .element$getName()))
  
  if(status_code(response) == 400){
    stop("Request is invalid")
  }
  
  if(status_code(response) == 403){
    stop(paste0("Request has not been executed in the '_system' database"))
  }
  
  if(status_code(response) == 404){
    stop(paste0("Database cannot be found in the server"))
  }
  
  return(TRUE)
}