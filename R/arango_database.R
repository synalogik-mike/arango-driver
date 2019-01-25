library(jsonlite)
library(httr)
library(R6)
library(magrittr)

#' Returns all the databases available on the server identified by the current connection 
#'
#' @param .connection the server connection to the ArangoDB instance
#' @param includeSystem TRUE iff the system databases must be included in the results, FALSE
#'                      otherwise
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
databases <- function(.connection, includeSystem=FALSE){
  
  if(is.null(.connection)){
    stop("Connection is NULL, please provide a valid 'ArangoConnection'")
  }
  
  if(class(.connection)[1] != "ArangoConnection"){
    stop("Only 'ArangoConnection' objects can be processed by aRango::databases")
  }
  
  connectionString <- .connection$getConnectionString()
  response <- httr::GET(paste0(connectionString,"/_api/database"))
  
  # Check the return value of the response
  if(status_code(response) == 400){
    stop("Request is invalid")
  }
  
  if(status_code(response) == 403){
    stop("Request has been made outside '_system' domain")
  }
  
  databasesList <- content(response)
  
  return(databasesList$result)
}