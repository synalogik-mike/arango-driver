library(R6)

.check_numeric_value <- function(value){
  if(!is.numeric(value)){
    stop("the value must be numeric")
  }
  return(value)
}

#' Creates a string expression representing a filter clause for AQL
#'
#' @param expr the expression to left as given in the resulting string
#' @param value the expression to be evaluated and printed in the resulting string
#'
#' @example age %lt% 33 gives "age < 33" 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
`%lt%` <- function(expr, value) {
  return(paste0(substitute(expr)," < ",toString(.check_numeric_value(value))))
}


#' Creates a string expression representing a filter clause for AQL
#'
#' @param expr the expression to left as given in the resulting string
#' @param value the expression to be evaluated and printed in the resulting string
#'
#' @example age %leq% 33 gives "age <= 33" 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
`%leq%` <- function(expr, value) {
  return(paste0(substitute(expr)," <= ",toString(.check_numeric_value(value))))
}


#' Creates a string expression representing a filter clause for AQL
#'
#' @param expr the expression to left as given in the resulting string
#' @param value the expression to be evaluated and printed in the resulting string
#'
#' @example age %gt% 33 gives "age > 33" 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
`%gt%` <- function(expr, value) {
  return(paste0(substitute(expr)," > ",toString(.check_numeric_value(value))))
}


#' Creates a string expression representing a filter clause for AQL
#'
#' @param expr the expression to left as given in the resulting string
#' @param value the expression to be evaluated and printed in the resulting string
#'
#' @example age %geq% 33 gives "age >= 33" 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
`%geq%` <- function(expr, value) {
  return(paste0(substitute(expr)," >= ",toString(.check_numeric_value(value))))
}


#' Creates a list representing an empty edge with an outbound from v1 to v2 
#'
#' @param v1 source document of the edge
#' @param v2 destination document of the edge
#'
#' @example v1 %->% v2 gives list(`_from`=v1, `_to`=v2) 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
`%->%` <- function(v1, v2) {
  .check_document(v1, v2)
  
  return(list(`_from`=v1$getKey(), `_to`=v2$getKey()))
}


#' Creates a list representing an empty edge with an outbound from v2 to v1 
#'
#' @param v1 destination document of the edge
#' @param v2 source document of the edge
#'
#' @example v1 %<-% v2 gives list(`_from`=v2, `_to`=v1) 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
`%<-%` <- function(v1, v2) {
  .check_document(v1, v2)
  
  return(list(`_from`=v2$getKey(), `_to`=v1$getKey()))
}


#' 
#'
#' @param definition a list containing a `_from` and a `_to` key
#' @param ... source document of the edge
#'
#' @example edge(data_science %->% math)
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
edge <- function(definition, ...) {
  
  edgeValues <- list(...)
  properties <- list(`_from` = definition$`_from`, `_to` = definition$`_to`)
  
  if(length(edgeValues) > 0){
    for(i in 1:length(edgeValues)){
      if(names(edgeValues[i]) != ""){
        properties[[names(edgeValues[i])]] <- edgeValues[[i]]
      }
    }
  }

  return(properties)
}


#' 
#'
#' @param relation an ArangoCollection or a string that represents an edge collection
#' @param edges a list of empty edges, the result of the e() function
#'
#' @seealso aRangodb::e
#' @example "requires" %:% e(data_science %->% math) returns a list(collection=..., edge=...) where 
#' edge contains a _from and a _to valid verticies
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#' @export
`%owns%` <- function(relation, edgeDefinition) {
  # edge definition must become variadic for multiple edges ...
  return(list(list(collection = relation, edge = edgeDefinition)))
}


.check_document <- function(doc1, doc2){
  if(class(doc1)[1] != "ArangoDocument" || class(doc2)[1] != "ArangoDocument"){
    stop("Relational infix operators (%->%, %<-%) requires two ArangoDocuments")
  }
}