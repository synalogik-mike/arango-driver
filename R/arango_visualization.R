library(jsonlite)
library(httr)
library(R6)
library(magrittr)
library(purrr)
library(visNetwork)
library(RColorBrewer)

#' Default elements coloring
#'
#' Calculates different coloring for the elements of the graph
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
.element_coloring <- function(edges, palette = brewer.pal(8, "Pastel1")){
  
  defColors <- palette
  colorList <- list()
  
  i <- 1
  for(edgeLabel in edges)
  {
    colorList[[edgeLabel]] <- defColors[i]
    i <- i+1
  }
  
  return(colorList)
}


.check_element <- function(element){
  if(is.null(element)){
    stop("Please provide a valid 'ArangoGraphConcrete' object or a list containing the elements to
         visualize the graph")
  }
  
  if(class(element)[1] == "ArangoGraphConcrete"){
    e <- element$.__enclos_env__$private$edges
    v <- element$.__enclos_env__$private$verticies
    
    nodes <- data.frame(
      id = unlist(lapply(v, function(el){ return(el$"_id") } )),
      label = unlist(lapply(v, function(el){ return(el$"_key") } )),
      group = unlist(lapply(v, function(el){ return(strsplit(el$"_id", "/")[[1]][1])})),
      stringsAsFactors = FALSE
    )
    
    edges <- data.frame(
      from = unlist(lapply(e, function(el){ return(el$"_from") } )), 
      to = unlist(lapply(e, function(el){ return(el$"_to") } )),
      group = unlist(lapply(e, function(el){ return(strsplit(el$"_id", "/")[[1]][1]) } )),
      stringsAsFactors = FALSE
    )
    
    return(list(v = nodes, e = edges))
  }
  else if(class(element)[1] == "list"){
    return(element)
  }
  else{
    stop("The element provided is not an 'ArangoConcreteGraph' or 'list'")
  }
}

#' Set visualization edges options
#'
#' Allows the user to set some options regarding the visualization of the edges of the graph
#'
#' @param .element can be an 'ArangoGraphConcrete' or a list containing other visualzation
#' options. Those lists are automatically created when this method is inside a pre-visualization
#' pipe. 
#' @param directions a list containing the direction to be visualized on the edge for each type
#' of relation contained into the graph, e.g. in a graph containing "friend_of" and "spouse" this parameter
#' can be list(friend_of="to", spouse="from")
#'
#' @return a list containing the visualization options updated
#'
#' @author Gabriele Galatolo, g.galatolo(at)kode.srl
gedges <- function(.element, directions = NULL){
  netOptions <- .check_element(.element)
  
  # Set the vertices icons (if defined)
  if(!is.null(directions)){
    if(!is.null(names(directions))){
      netOptions$e$arrows <- unlist(apply(netOptions$e, 1, function(el){
                                                        if(el[['group']] %in% names(directions))
                                                          return(directions[el[['group']]])
                                                        else
                                                          return("to")
                                                      }))
    }
  }
  
  return(netOptions)
}

gnodes <- function(.element, icons = NULL, colors = NULL){
  netOptions <- .check_element(.element)
  
  # Set the vertices icons (if defined)
  if(!is.null(icons)){
    
    netOptions$v$shape <- unlist(apply(netOptions$v, 1, function(el)
                                                        {
                                                          if(el[['group']] %in% names(icons))
                                                            return("icon")
                                                          else
                                                            return(NA)
                                                        } 
                                                      ))
    netOptions$v$icon.code <- unlist(apply(netOptions$v, 1, 
                                            function(el){
                                              if(el[['group']] %in% names(icons))
                                                return(icons[el[['group']]])
                                              else
                                                return(NA)
                                            } 
                                           )
                                     )
  }
  
  return(netOptions)
}

gwidth <- function(.element, width){
  netOptions <- .check_element(.element)
  netOptions[["width"]] <- width
  
  return(netOptions)
}


gheight <- function(.element, height){
  netOptions <- .check_element(.element)
  netOptions[["height"]] <- height
  
  return(netOptions)
}
  

glegend <- function(.element, nodes=TRUE, edges=FALSE){
  netOptions <- .check_element(.element)
  
  if(nodes){
    netOptions[["legend.nodes"]] <- nodes
  }
  
  if(edges){
    netOptions[["legend.edges"]] <- edges
  }
  
  return(netOptions)
}

visualize <- function(.element){
  netOptions <- .check_element(.element)
  
  if(!("height" %in% netOptions)){
    netOptions[["height"]] <- "1000px"
  }
  
  if(!("width" %in% netOptions)){
    netOptions[["width"]] <- "100%"
  }
  
  # Are verticies and edges colored? If not execute coloring
  if(!("color" %in% colnames(netOptions$v))){
    nodeColor <- .element_coloring(
                    unique(unlist(apply(netOptions$v, 1, function(el) {el[["group"]]} ))), brewer.pal(8, "Pastel1")
                 )
    
    netOptions$v$color <- unlist(apply(netOptions$v, 1, function(el) nodeColor[el[["group"]]]))
    
    if("icon.code" %in% colnames(netOptions$v)){
      netOptions$v$icon.color <- netOptions$v$color
    }
  }
  
  if(!("color" %in% colnames(netOptions$e))){
    edgeColor <- .element_coloring(
      unique(unlist(apply(netOptions$e, 1, function(el) el[['group']] ))), brewer.pal(8, "Pastel1")
    )
    
    netOptions$e$color <- unlist(apply(netOptions$e, 1, function(el) edgeColor[el[['group']]]))
  }
  
  # Creating the stub of network
  networkVisualized <- visNetwork(nodes = netOptions$v, edges = netOptions$e,
                                  width = netOptions$width, height = netOptions$height) %>%
                       addFontAwesome()
  
  # Adding legend?
  if("legend.nodes" %in% names(netOptions) && "legend.edges" %in% names(netOptions)){
    ledges <- data.frame(color = unique(netOptions$e$color), label = unique(netOptions$e$group))
    lnodes <- data.frame(color = unique(netOptions$v$color), label = unique(netOptions$v$group))
    
    networkVisualized <- networkVisualized %>%
      visLegend(addEdges = ledges, addNodes = lnodes, useGroups = FALSE)
  }
  else if("legend.nodes" %in% names(netOptions) && !("legend.edges" %in% names(netOptions))){
    lnodes <- data.frame(color = unique(netOptions$v$color), label = unique(netOptions$v$group))
    
    networkVisualized <- networkVisualized %>%
      visLegend(addNodes = lnodes, useGroups = FALSE)
  }
  else if(!("legend.nodes" %in% names(netOptions)) && "legend.edges" %in% names(netOptions)){
    ledges <- data.frame(color = unique(netOptions$e$color), label = unique(netOptions$e$group))
    
    networkVisualized <- networkVisualized %>%
      visLegend(addEdges = ledges, useGroups = FALSE)
  }
  
  return(networkVisualized)
}