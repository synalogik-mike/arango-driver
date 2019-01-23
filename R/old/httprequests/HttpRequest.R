library(jsonlite)
library(httr)
library(R6)

HttpRequest <- R6Class (

  "HttpRequest",

  public = list(

      #' Creates an empty new HTTP request
      initialize = function(host, port, url){
        private$host = host
        private$port = port
        private$url = url
      },


      #' Add an header to the specified request
      #'
      #' @param key the header value for which a parameter is specified
      #' @param value the value for the given header
      addHeader = function(key, value){

      },


      #' Add a query string to be added to the url
      #'
      #' @param key the header value for which a parameter is specified
      #' @param value the value for the given header
      addQueryParameters = function(key, value){

      },


      #' Returns
      process = function(){

      }
  ),

  private = list(
    host = NULL,
    port = NULL,
    url = NULL
  )

)
