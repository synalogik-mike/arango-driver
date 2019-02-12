library(R6)

.check_numeric_value <- function(value){
  if(!is.numeric(value)){
    stop("the value must be numeric")
  }
  return(value)
}

#' Creates a string expression representing an AQL filter "less than" clause for
#' numeric values
#'
#' @param expr the expression to be left as given in the resulting string
#' @param value the expression to be evaluated and printed in the resulting string
#'
#' @example age %lt% 33 gives "age < 33" 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#' @export
`%lt%` <- function(expr, value) {
  return(paste0(substitute(expr)," < ",toString(.check_numeric_value(value))))
}


#' Creates a string expression representing an AQL filter "less or equal than" clause for
#' numeric values
#'
#' @param expr the expression to be left as given in the resulting string
#' @param value the expression to be evaluated and printed in the resulting string
#'
#' @example age %leq% 33 gives "age <= 33" 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#' @export
`%leq%` <- function(expr, value) {
  return(paste0(substitute(expr)," <= ",toString(.check_numeric_value(value))))
}


#' Creates a string expression representing an AQL filter "greater than" clause for
#' numeric values
#'
#' @param expr the expression to be left as given in the resulting string
#' @param value the expression to be evaluated and printed in the resulting string
#'
#' @example age %gt% 33 gives "age > 33" 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#' @export
`%gt%` <- function(expr, value) {
  return(paste0(substitute(expr)," > ",toString(.check_numeric_value(value))))
}


#' Creates a string expression representing an AQL filter "greater or equal than" clause for
#' numeric values
#'
#' @param expr the expression to be left as given in the resulting string
#' @param value the expression to be evaluated and printed in the resulting string
#'
#' @example age %geq% 33 gives "age >= 33" 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#' @export
`%geq%` <- function(expr, value) {
  return(paste0(substitute(expr)," >= ",toString(.check_numeric_value(value))))
}


#' Creates a list representing an empty edge with an outbound from v1 to v2 
#'
#' @param v1 source document of the edge
#' @param v2 destination document of the edge
#'
#' @return a list containing the `_from` and the `_to` attributes needed for an edge
#'
#' @example v1 %->% v2 gives list(`_from`=v1, `_to`=v2) 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#' @export
`%->%` <- function(v1, v2) {
  .check_document(v1, v2)
  
  return(list(`_from`=v1$getId(), `_to`=v2$getId()))
}


#' Creates a list representing an empty edge with an outbound from v2 to v1 
#'
#' @param v1 destination document of the edge
#' @param v2 source document of the edge
#'
#' @return a list containing the `_from` and the `_to` attributes needed for an edge
#'
#' @example v1 %<-% v2 gives list(`_from`=v2, `_to`=v1) 
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
#' @export
`%<-%` <- function(v1, v2) {
  .check_document(v1, v2)
  
  return(list(`_from`=v2$getId(), `_to`=v1$getId()))
}


#' Creates a list with the _from/_to indication used to define an anonymous edge, i.e. still without
#' relation for which the edge is defined. If indicated, the attributes (in key-value form) for the resulting anonymous edge
#'
#' @param definition a list containing a `_from` and a `_to` key
#' @param ... pairs of key-values representing attributes of this edge
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


#' Assign a relation, i.e. an edge collection, to an anonymous edge, i.e. a list containing at least _from/_to
#' attributes. 
#'
#' @param relation a string that represents an edge collection
#' @param edges a list containing an anonymous edge (TODO, this must be a list of anonymous edges)
#'
#' @seealso edge
#' @example "requires" %:% edge(data_science %->% math) returns a list(collection=..., edge=...) where 
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