.check_connection <- function(.connection){
  if(is.null(.connection)){
    stop("Connection is NULL, please provide a valid 'ArangoConnection'")
  }
  
  if(class(.connection)[1] != "ArangoConnection"){
    stop("Only 'ArangoConnection' objects can be processed by this method")
  }
}

#' Get all the users
#' 
#' Returns all the available users given the connection passed as argument 
#'
#' @param .connection the ArangoConnection handler
#'                      
#' @return a character vector with all the users available in the server
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
users <- function(.connection){
  
  .check_connection(.connection)
  
  connString <- .connection$getConnectionString()
  response <- httr::GET(
    paste0(connString,"/_api/user/"),
    add_headers(Authorization = .connection$.__enclos_env__$private$auth)
  )
  
  # Check the return value of the response
  if(httr::status_code(response) == 401){
    stop("The logged user have no access to the _system database")
  }
  
  if(httr::status_code(response) == 403){
    stop("The logged user have no valid permissions for this server")
  }
  
  usersList <- httr::content(response)
  
  return(sapply(usersList$result, function(u){u$user}))
}

#' Add new user
#' 
#' Add a new user to the running Arango instance
#'
#' @param .connection the ArangoConnection handler
#' @param username the username of the new user
#' @param password the password of the new user
#'                      
#' @return a character vector with all the users available in the server
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
add_user <- function(.connection, username, password){
  stop("not implemented yet")
}

#' Get all the users
#' 
#' Returns all the available users given the connection passed as argument 
#'
#' @param .connection the ArangoConnection handler
#'                      
#' @return a character vector with all the users available in the server
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
edit_user <- function(.connection, username, password){
  stop("not implemented yet")
}

#' Get all the users
#' 
#' Returns all the available users given the connection passed as argument 
#'
#' @param .connection the ArangoConnection handler
#'                      
#' @return a character vector with all the users available in the server
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
remove_user <- function(.connection, username, password){
  stop("not implemented yet")
}

#' User Access level to the resource
#'
#' Returns the access levelo of the user to the given resource (database/collection)
#'
#'
user_access_level <- function(.element, user){
  stop("not implemented yet")
}

#' Set user Access level to the resource
#'
#' Returns the access levelo of the user to the given resource (database/collection)
#'
#'
user_access_level_set <- function(.element, user){
  stop("not implemented yet")
}