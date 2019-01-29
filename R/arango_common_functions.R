# =========================================================================================
# COMMON FUNCTIONS, i.e. set of functions that have the same signature in different context
# =========================================================================================

#' Drop an existing database or collection
#'
#' @param .element can be an ArangoDatabase OR ArangoCollection, other objects raise exception
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
drop <- function(.element){
  if(is.null(.element)){
    stop("Database or Collection is NULL, please provide a valid 'ArangoDatabase' or an 'ArangoCollection'")
  }
  
  if(class(.element)[1] == "ArangoDatabase"){
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
  else if(class(.element)[1] == "ArangoCollection"){
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
  else{
    stop("Only 'ArangoDatabase' objects can be processed by aRango::drop")
  }
  
  return(FALSE)
}