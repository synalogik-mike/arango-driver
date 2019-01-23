library(jsonlite)
library(httr)
library(R6)

#'
#'
#'
aRango_query <- R6Class (
  "ArangoQuery",

  public = list(

    #' Creates a new query executor
    #'
    #' @param arangoConnection an aRango_connection
    #' @param name the name of the collection to proxy
    initialize = function(arangoConnection){}

    #' Execute the query
    #'
    #' @param arangoConnection an aRango_connection
    #' @param name the name of the collection to proxy
    execute = function(){
    }

  ),

  private = list(

  )
)
