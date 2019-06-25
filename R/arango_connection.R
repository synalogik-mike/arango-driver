#' Creates a connection object to be used for subsequent requests to the given server.
#'
#' @param host the server address where the ArangoDB server is up and running
#' @param port the server port where the ArangoDB server is up and running
#' @param username the username that wants to authenticate into the system
#' @param password the password of the user
#' 
#' @return an ArangoConnection object used to handle requests to the given Arango server
#' 
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
arango_connection <- function(host, port, username, password){
  
  if(is.null(host)){
    stop("to setup a connection you must indicate a 'host'")
  }
  
  if(is.null(port)){
    stop("to setup a connection you must indicate a 'port'")
  }
  
  return(.aRango_connection$new(host, port, RCurl::base64Encode(paste(username,":",password, sep="")[1])))
}



#' An ArangoConnection is a class that contains and manages the connection with one specific 
#' instance of ArangoDB. Basically this object must be used to get databases collections, graphs
#' or to interact in other ways with an existing instance of the db.
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#'
.aRango_connection <- R6::R6Class (
  "ArangoConnection",
  
  public = list(
    #' Creates a new connection to a server running ArangoDB
    #'
    #' @param host the address on which the Arango instance is running
    #' @param port the port on the server on which the Arango instance is running
    #' @param port the authentication token for HTTP Basic authentication (base64 of username:password)
    #' 
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    initialize = function(host, port, auth) {
      private$host = host
      private$port = port
      private$auth = paste0("Basic ", auth)
      
      arangoVersionRequest <- paste0("http://", host, ":", port, "/_api/version")
      
      # Waiting for version response
      tryCatch({
        arangoVersionResponse <- httr::GET(
          arangoVersionRequest,
          add_headers(Authorization = private$auth)
        )
      }, 
      error = function(e) {
        stop("Server not reachable")
      })
      
      # Check the response and fill properly the internal state. Reject connection if the 200 is not
      # returned
      arangoVersionBody <- httr::content(arangoVersionResponse)
      arangoResponse <- httr::status_code(arangoVersionResponse)
      
      if(arangoResponse == 200){
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
      }
      else{
        private$server = "Server up and running, but not entitled as admin"
        private$version = "Server up and running, but not entitled as admin"
        private$license = "Server up and running, but not entitled as admin"
      }
    },
    
    #' Returns the server address where the Arango instance is running
    #'
    #' @return the server address where the Arango instance is running
    #' 
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getServer = function() {
      return(private$server)
    },
    
    #' Returns the version of the Arango instance
    #'
    #' @return the version of the Arango instance
    #' 
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getVersion = function() {
      return(private$version)
    },
    
    #' Returns the license of the Arango instance
    #'
    #' @return the license of the Arango instance
    #' 
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getLicense = function() {
      return(private$license)
    },
    
    #' Returns a string in the form of "http://<localhost>:<port>" useful to execute new requests
    #'
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getConnectionString = function() {
      return(paste0("http://", private$host, ":", private$port))
    }
  ),
  
  private = list(
    host = NULL,
    port = NULL,
    server = NULL,
    version = NULL,
    license = NULL,
    auth = NULL
  )
)