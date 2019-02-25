library(jsonlite)
library(httr)
library(R6)

.check_element.aql <- function(.element){
  if(is.null(.element)){
    stop("Database is NULL, please provide a valid 'ArangoDatabase'")
  }
  
  if(class(.element)[1] != "ArangoDatabase"){
    stop("Only 'ArangoDatabase' objects can be processed by aRango::aql")
  }
}

#' AQL query wrapper
#' 
#' Create an R function that interprets the statement as AQL query. Every
#' bindvar of the statement will become a mandatory parameter of the function.
#'
#' @param .element a valid ArangoDatabase object
#' @param statement an AQL statement
#' 
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#' 
#' @examples
#' paperWithTitle <- db %>% aql("FOR p IN Papers FILTER p.title==@search RETURN p")
#' paper <- paperWithTitle(search="A study in scarlet")
#'
aql <- function(.element, statement){
  
  # Check connection
  .check_element.aql(.element)
  
  if(is.null(statement)){
    stop("Statement cannot be null, provide an AQL statement")
  }
  
  # Retrieve parameters that has to be bound during the call
  param.names <- NULL
  for(element in unlist(strsplit(statement, split = "[= }{,;:'?|!]+"))){
    if(startsWith(element, "@")){
      if(is.null(param.names)){
       param.names <- c(unlist(strsplit(element, split = "@"))[2])
      }
      else{
        param.names <- c(param.names, unlist(strsplit(element, split = "@"))[2])
      }
    }
  }

  # Request parse and correction from the server
  connectionString <- .element$.__enclos_env__$private$connectionStringRequest
  parseAqlEndpoint <- paste0(.element$.__enclos_env__$private$connectionStringRequest, "/_api/query")
  parsingResultResponse <- httr::POST(parseAqlEndpoint, encode="json", body = list(query=statement))
  parsingResult <- content(parsingResultResponse)
  
  if(parsingResult$code == 400){
    stop(parsingResult$errorMessage)
  }
  
  # Return the function
  rFun <- function(){
    # GET THE PARAMETERS
    bindVarsList <- list()
    
    for(p in param.names){
      bindVarsList[[p]] <- get(p)
    }
    
    # EXECUTE THE REQUEST
    documents <- list()
    
    # Creates the cursor and iterate over it to retrieve the entire collection
    resultsBatch <- httr::POST(paste0(connectionString,"/_api/cursor"),
                                  body = list(
                                    query=statement,
                                    count = FALSE,
                                    batchSize = 50,
                                    bindVars = bindVarsList
                                  ),
                                  encode = "json")
    cursorResponse <- content(resultsBatch)
    
    if(cursorResponse$code != "200" && cursorResponse$code != "201" ){
      stop(paste0("ArangoCursor not created: ", cursorResponse$errorMessage))
    }
    
    # Save the cursor id, it is needed for all the subsequent access to the cursor
    cursor <- cursorResponse$id
    i <- 0
    
    for(document in cursorResponse$result){
      documents[[paste0("doc",i)]] <- document
      i <- i+1
    }
    
    # Iterating the entire cursor
    while(cursorResponse$hasMore){
      
      # Requesting next data batch
      resultsBatch <- httr::PUT(paste0(connectionString,"/_api/cursor/",cursor))
      cursorResponse <- content(resultsBatch)
      
      if(cursorResponse$code != "200" && cursorResponse$code != "201" ){
        stop("Something were wrong during the retrieval of the documents of this collection (arango cursor not created)")
      }
      
      for(document in cursorResponse$result){
        documents[[paste0("doc",i)]] <- document
        i <- i+1
      }
    }
    
    return(documents)
  }
  
  # Parameters to bound
  formalParameters <- vector("list", length(param.names))
  names(formalParameters) <- param.names
  formals(rFun) <- formalParameters
  
  return(rFun)
}