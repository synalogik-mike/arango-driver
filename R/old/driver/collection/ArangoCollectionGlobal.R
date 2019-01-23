library(jsonlite)
library(httr)
library(R6)

#' Returns a list containing all the names of the collections available into
#' the system connected with the given connection
#'
#' @param arangoConnection an aRango_connection
#' @seealso aRango_connection
#'
#' @return a list containing all the names of the collections available into
#' the system connected with the given connection
aRango_collections_available <- function(arangoConnection){
  collectionResults <- character()
  results <- NULL
  connectionString <- arangoConnection$getConnectionString()

  allCollectionsResponse <- httr::GET(paste0(connectionString,"/_api/collection/"))

  stop_for_status(allCollectionsResponse)
  allCollectionsBody <- content(allCollectionsResponse)


  if(!is.null(allCollectionsBody$result)){
    results <- allCollectionsBody$result
  }
  else{
    warning("Server didn't send the 'result' attribute")
  }

  for(result in results){
    if(!result$isSystem){
      collectionResults <- c(collectionResults, result$name)
    }
  }

  return(collectionResults)
}


#' Returns a list containing all the collections available into
#' the system connected with the given connection
#'
#' @param arangoConnection an aRango_connection
#' @seealso aRango_connection
#'
#' @return a list containing all the collections available into the system
#' mapped by their name
aRango_collections_get <- function(arangoConnection){
  collectionResults <- list()
  results <- NULL
  connectionString <- arangoConnection$getConnectionString()

  allCollectionsResponse <- httr::GET(paste0(connectionString,"/_api/collection/"))

  stop_for_status(allCollectionsResponse)
  allCollectionsBody <- content(allCollectionsResponse)

  if(!is.null(allCollectionsBody$result)){
    results <- allCollectionsBody$result
  }
  else{
    warning("Server didn't send the 'result' attribute")
  }

  for(result in results){
    if(!result$isSystem){
      collection <- aRango_collection$new(arangoConnection, result$name)
      collectionResults[[result$name]] <- collection
    }
  }

  return(collectionResults)
}


#' Returns a collection with the given name, if any, using the
#' given aRango_connection
#'
#' @param arangoConnection an aRango_connection
#' @seealso aRango_connection
#'
#' @return a collection with the given name, if any
aRango_collection_get <- function(arangoConnection, name){

}
