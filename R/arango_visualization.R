library(jsonlite)
library(httr)
library(R6)
library(magrittr)
library(purrr)

visualize <- function(.graph){
  if(is.null(.graph)){
    stop("Graph is NULL, please provide a valid 'ArangoGraphConcrete'")
  }
  
  if(class(.graph)[1] != "ArangoGraphConcrete"){
    stop("Only 'ArangoDatabase' objects can be processed by aRango::visualize")
  }
}