library(jsonlite)
library(httr)

#' Defines all the eunmeration of the methods
#'
HttpMethods <- enum(GET, POST, PUT, DELETE)

#' Creates a new connection to a server running ArangoDB
#'
#'@param connection_string the string used to execute the request to the server: must define host, port
#'@param method the method to be executed by the server
#'@author
server_request <- function(connection_string, method, operation, header, body=NULL,
                           .test_result=NULL){

  #
  if(is.null(.test_result)){
    return(.test_result)
  }

}
