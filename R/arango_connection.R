library(jsonlite)
library(httr)
library(R6)

#' Creates a connection object to be used for subsequent requests to the given server.
#'
#' @param host the server address where the ArangoDB server is up and running
#' @param port the server port where the ArangoDB server is up and running
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
connect <- function(host, port){
  
  if(is.null(host)){
    stop("to setup a connection you must indicate a 'host'")
  }
  
  if(is.null(port)){
    stop("to setup a connection you must indicate a 'port'")
  }
  
  return(.aRango_connection$new(host, port))
}

#' An ArangoConnection is a class that contains and manages the connection with one specific 
#' instance of ArangoDB. Basically this object must be used to get databases collections, graphs
#' or to interact in other ways with an existing instance of the db.
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#'
.aRango_connection <- R6Class (
  "ArangoConnection",
  
  public = list(
    #' Creates a new connection to a server running ArangoDB
    #'
    #' @param host the address on which the Arango instance is running
    #' @param port the port on the server on which the Arango instance is running
    #' @param database OPTIONAL, the name of the database to which connect
    #'
    initialize = function(host, port) {
      private$host = host
      private$port = port
      
      arangoVersionRequest <- paste0("http://", host, ":", port, "/_api/version")
      
      # Waiting for version response
      arangoVersionResponse <- httr::GET(arangoVersionRequest)
      
      # Check the response and fill properly the internal state. Reject connection if the 200 is not
      # returned
      stop_for_status(arangoVersionResponse)
      arangoVersionBody <- content(arangoVersionResponse)
      
      if (!is.null(arangoVersionBody$server)) {
        private$server = arangoVersionBody$server
      }
      else{
        warning("Server didn't send the 'server' attribute")
      }
      
      if (!is.null(arangoVersionBody$version)) {
        private$version = arangoVersionBody$version
      }
      else{
        warning("Server didn't send the 'version' attribute")
      }
      
      if (!is.null(arangoVersionBody$license)) {
        private$license = arangoVersionBody$license
      }
      else{
        warning("Server didn't send the 'license' attribute")
      }
      
    },
    
    #' Returns the server indicated by the instance running on this connection
    #'
    #'
    getServer = function() {
      return(private$server)
    },
    
    #' Returns the version of the server indicated by the instance running on this connection
    #'
    #'
    getVersion = function() {
      return(private$version)
    },
    
    #' Returns the license indicated by the instance running on this connection
    #'
    #'
    getLicense = function() {
      return(private$license)
    },
    
    #' Returns a string in the form of "http://<localhost>:<port>" useful to execute new requests
    #'
    #'
    getConnectionString = function() {
      return(paste0("http://", private$host, ":", private$port))
    }
  ),
  
  private = list(
    host = NULL,
    port = NULL,
    server = NULL,
    version = NULL,
    license = NULL
  )
)