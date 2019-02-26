.check_connection <- function(.connection){
  if(is.null(.connection)){
    stop("Connection is NULL, please provide a valid 'ArangoConnection'")
  }
  
  if(class(.connection)[1] != "ArangoConnection"){
    stop("Only 'ArangoConnection' objects can be processed by aRango::databases")
  }
}


#' Get all databases
#' 
#' Returns all the databases available in the server identified by the current connection 
#'
#' @param .connection the ArangoConnection handler
#' @param includeSystem TRUE iff the system databases must be included in the results, FALSE
#'                      otherwise
#'                      
#' @return a character vector with all the databases available in the server
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
databases <- function(.connection, includeSystem=FALSE){
  
  .check_connection(.connection)
  
  connectionString <- .connection$getConnectionString()
  response <- httr::GET(paste0(connectionString,"/_api/database"))
  
  # Check the return value of the response
  if(httr::status_code(response) == 400){
    stop("Request is invalid")
  }
  
  if(httr::status_code(response) == 403){
    stop("Request has been made outside '_system' domain")
  }
  
  databasesList <- httr::content(response)
  
  return(databasesList$result)
}



#' Get or create database
#' 
#' Return an object representing the database with the given name:
#' the object must be used to handle requests to the database.
#' 
#' @param .connection the ArangoConnection handler
#' @param name the name of the database, the default is "_system" that is ArangoDB default one
#' @param createOnFail if the database were not found creates it. If the parameter is set to TRUE
#'                     and the default database is requested the function fails. (default FALSE)             
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
arango_database <- function(.connection, name="_system", createOnFail=FALSE){
  .check_connection(.connection)
  
  if(is.null(name)){
    stop("Name of database cannot be NULL")
  }
  
  # if createOnFail try to create the database: if the db exist, then go ahead,
  # otherwise it is a prerequisite to return the requested db
  if(createOnFail){
    databaseInfoRequest <- paste0(.connection$getConnectionString(), "/_api/database")
    
    # Waiting for version response
    response <- httr::POST(databaseInfoRequest, encode = "json", body = list(name=name))
  }
  
  db <- .aRango_database$new(.connection, name)
  
  return(db)
}



#' An ArangoDatabase is a class where instances are used to handle the interaction with
#' real databases on the server.
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
.aRango_database <- R6::R6Class (
  "ArangoDatabase",
  
  public = list(
    #' Creates a new interface to some database available through the given connection
    #'
    #' @param connection an ArangoConnection with an ArangoDB server
    #' @param dbname the database name to which connect to 
    #'
    initialize = function(connection, dbname) {
      
      if(is.null(connection)){
        stop("Connection is NULL, please provide a valid 'ArangoConnection'")
      }
      
      if(class(connection)[1] != "ArangoConnection"){
        stop("Only 'ArangoConnection' objects can be processed by the class ArangoDatabase")
      }
      
      if(is.null(dbname)){
        stop("dbname is NULL, please provide a valid database name")
      }
      
      private$originalConnection <- connection$getConnectionString()
      private$connectionStringRequest <- paste0(connection$getConnectionString(), "/_db/", dbname)
      databaseInfoRequest <- paste0(private$connectionStringRequest, "/_api/database/current")
      
      # Waiting for version response
      response <- httr::GET(databaseInfoRequest)
      
      # Check response status
      if(status_code(response) == 400){
        stop("Request is invalid")
      }
      
      if(status_code(response) == 404){
        stop(paste0("Database ", dbname, " not found. Creates it on the server or call the database 
                    with the optional parameter 'createOnFail=TRUE'"))
      }
      
      # Response is ok, fill the internal state
      dbInformation <- httr::content(response)
      private$dbname <- dbname
      private$isSystem <- dbInformation$result$isSystem
      private$id <- dbInformation$result$id
    },
    
    #' Returns the name of the database
    #' 
    #' @return the name of the database
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getName = function(){
      return(private$dbname)
    },
    
    #' Returns TRUE iff this object is connected to a system database, FALSE otherwise
    #' 
    #' @return TRUE iff this object is connected to a system database, FALSE otherwise
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    isSystemDatabase = function(){
      return(private$isSystem)
    },
    
    #' Returns the identifier of the database
    #' 
    #' @return the identifier of the database
    #' @author Gabriele Galatolo, g.galatolo(at)kode.srl
    getId = function(){
      return(private$id)
    }
  ),
  
  private = list(
    dbname = NULL,
    connectionStringRequest = NULL,
    originalConnection = NULL,
    isSystem = FALSE,
    id = NULL
  )
)