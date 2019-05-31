.check_connection <- function(.connection){
  if(is.null(.connection)){
    stop("Connection is NULL, please provide a valid 'ArangoConnection'")
  }
  
  if(class(.connection)[1] != "ArangoConnection"){
    stop("Only 'ArangoConnection' objects can be processed by this method")
  }
}

.get_string_from_access <- function(access){
  
  if(access == resource_access$ADMIN || access == "rw"){
    return("rw")
  }
  
  if(access == resource_access$ACCESS || access == "ro"){
    return("ro")
  }
  
  return("none")
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
#' @return TRUE if the operation succeeded
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
add_user <- function(.connection, username, password){
  .check_connection(.connection)
  
  connString <- .connection$getConnectionString()
  response <- httr::POST(
    paste0(connString,"/_api/user"),
    add_headers(Authorization = .connection$.__enclos_env__$private$auth),
    encode = "json",
    body = list(user=username, passwd=password)
  )
  
  # Check the return value of the response
  if(httr::status_code(response) == 400){
    stop("Request is malformed or mandatory data is missing from request")
  }
  
  if(httr::status_code(response) == 401){
    stop("You have no access level to the '_system' database")
  }
  
  if(httr::status_code(response) == 403){
    stop("You have no access server access level")
  }

  if(httr::status_code(response) == 409){
    stop("A user with the same name already exists")
  } 

  if(httr::status_code(response) == 201){
    return(TRUE)
  }
  
  stop("You are not allowed to create new users")
}


#' Edit a user
#' 
#' Modify the password of the given user
#'
#' @param .connection the ArangoConnection handler
#'                      
#' @return TRUE if the operation succeeded
#' 
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
edit_user <- function(.connection, username, password){
  
  .check_connection(.connection)
  
  connString <- .connection$getConnectionString()
  response <- httr::PATCH(
    paste0(connString,"/_api/user/", username),
    add_headers(Authorization = .connection$.__enclos_env__$private$auth),
    encode = "json",
    body = list(passwd=password)
  )
  
  # Check the return value of the response
  if(httr::status_code(response) == 400){
    stop("Request is malformed or mandatory data is missing from request")
  }
  
  if(httr::status_code(response) == 401){
    stop("You have no access level to the '_system' database")
  }
  
  if(httr::status_code(response) == 403){
    stop("You have no access server access level")
  }
  
  if(httr::status_code(response) == 404){
    stop("A user with the given name does not already exists")
  } 
  
  return(TRUE)
}


#' Remove a user
#' 
#' Remove an existing user, if any
#'
#' @param .connection the ArangoConnection handler
#' @param name the user to be removed
#'                      
#' @return TRUE if the operation succeeded
#' 
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
remove_user <- function(.connection, username){
  
  .check_connection(.connection)
  
  connString <- .connection$getConnectionString()
  response <- httr::DELETE(
    paste0(connString,"/_api/user/", username),
    add_headers(Authorization = .connection$.__enclos_env__$private$auth)
  )
  
  if(httr::status_code(response) == 401){
    stop("You have no access level to the '_system' database")
  }
  
  if(httr::status_code(response) == 403){
    stop("You have no access server access level")
  }
  
  if(httr::status_code(response) == 404){
    stop("A user with the given name does not already exists")
  } 
  
  return(TRUE)
}


#' User access level for a database
#'
#' Returns the access level of the given user for the given database
#' 
#' @param user the user to check
#' @param database the database to check
#' 
#' @return the access level of the given user for the given database
#'
user_access_level_database <- function(.connection, user, database){
  
  .check_connection(.connection)
  
  connString <- .connection$getConnectionString()
  response <- httr::GET(
    paste0(connString, "/_api/user/",user,"/database/",database),
    add_headers(Authorization = .connection$.__enclos_env__$private$auth)
  )
  
  if(httr::status_code(response) == 400){
    stop("Wrong privileges")
  }
  
  if(httr::status_code(response) == 401){
    stop("You have no access level to the '_system' database")
  }
  
  if(httr::status_code(response) == 403){
    stop("You have no access server access level")
  }
  
  if(httr::status_code(response) == 200){
    return(httr::content(response)$result)
  }

  stop("Something were wrong")
}

#' User access level for a collection
#'
#' Returns the access level of the given user for the given collection
#' 
#' @param user the user to check
#' @param collection the collection to check
#' 
#' @return the access level of the given user for the given collection
#'
user_access_level_collection <- function(.connection, user, database, collection){
  
  .check_connection(.connection)
  
  connString <- .connection$getConnectionString()
  response <- httr::GET(
    paste0(connString, "/_api/user/",user,"/database/",database,"/",collection),
    add_headers(Authorization = .connection$.__enclos_env__$private$auth)
  )
  
  if(httr::status_code(response) == 400){
    stop("Wrong privileges")
  }
  
  if(httr::status_code(response) == 401){
    stop("You have no access level to the '_system' database")
  }
  
  if(httr::status_code(response) == 403){
    stop("You have no access server access level")
  }
  
  if(httr::status_code(response) == 200){
    return(httr::content(response)$result)
  }
  
  stop("Something were wrong")
}


#' Set user access level for a database
#'
#' Set the access level of the given user for the given database
#' 
#' @param user the user to check
#' @param database the database to check
#' @param grant the level of the access
#' 
#'
set_user_access_level_database <- function(.connection, user, database, grant){
  
  .check_connection(.connection)
  
  grantDb <- .get_string_from_access(grant)
  
  connString <- .connection$getConnectionString()
  response <- httr::PUT(
    paste0(connString, "/_api/user/",user,"/database/",database),
    add_headers(Authorization = .connection$.__enclos_env__$private$auth),
    encode = "json",
    body = list(grant = grantDb)
  )
  
  if(httr::status_code(response) == 400){
    stop("Wrong privileges")
  }
  
  if(httr::status_code(response) == 401){
    stop("You have no access level to the '_system' database")
  }
  
  if(httr::status_code(response) == 403){
    stop("You have no access server access level")
  }
  
  return(TRUE)
}


#' Set user access level for a collection
#'
#' Set the access level of the given user for the given collection
#' 
#' @param user the user to check
#' @param database the database to check
#' @param collection the collection to check
#' @param grant the level of the access
#' 
#' @return the access level of the given user for the given collection
#'
set_user_access_level_collection <- function(.connection, user, database, collection, grant){
  
  .check_connection(.connection)
  
  grantDb <- .get_string_from_access(grant)
  
  connString <- .connection$getConnectionString()
  response <- httr::PUT(
    paste0(connString, "/_api/user/",user,"/database/",database,"/",collection),
    add_headers(Authorization = .connection$.__enclos_env__$private$auth),
    encode = "json",
    body = list(grant = grantDb)
  )
  
  if(httr::status_code(response) == 400){
    stop("Wrong privileges")
  }
  
  if(httr::status_code(response) == 401){
    stop("You have no access level to the '_system' database")
  }
  
  if(httr::status_code(response) == 403){
    stop("You have no access server access level")
  }
  
  return(TRUE)
}