library(jsonlite)
library(httr)
library(R6)

#' The ArangoDocument class encapsulate the representation and the methods useful to manage
#' the retrieval, representation and updates of specific documents belonging to Arango collections.
#' Each document is strictly related to some collection and within the environment SHOULD exists
#' only one copy of this object.
#'
#'
aRango_document <- R6Class (
  "ArangoDocument",

  public = list(

    #' Initialize the arango document
    #'
    #'
    initialize = function(connectionString, document){

      private$connectionString <- connectionString
      idSplit <- strsplit(document$`_id`, split = "/")

      private$documentValues <- document
      private$currentRevision <- document$`_rev`
      private$documentId <- idSplit[[1]][2]
      private$originalCollection <- idSplit[[1]][1]

      # Removing _id, _key and _revision from available values
      private$documentValues$`_id` <- NULL
      private$documentValues$`_rev` <- NULL
      private$documentValues$`_key` <- NULL
    },

    #' Update the document
    #'
    #'
    update = function(...){

    },

    collection = function(){
      return(private$originalCollection)
    },

    id = function(){
      return(private$documentId)
    },

    revision = function(){
      return(private$currentRevision)
    },

    values = function(){
      return(private$documentValues)
    },

    availableValues = function(){
      return(names(private$documentValues))
    }
  ),

  private = list(
    documentValues = NULL,
    originalCollection = NULL,
    documentId = NULL,
    currentRevision = NULL,
    connectionString = NULL
  )
)
