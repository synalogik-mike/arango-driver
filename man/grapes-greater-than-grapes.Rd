% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/arango_common_operators.R
\name{\%->\%}
\alias{\%->\%}
\title{Outbound edge operator}
\usage{
v1 \%->\% v2
}
\arguments{
\item{v1}{source document of the edge}

\item{v2}{destination document of the edge}
}
\value{
a list containing the `_from` and the `_to` attributes needed for an edge
}
\description{
Creates a list representing an empty edge with an outbound from v1 to v2 
v1 %->% v2 return list(`_from`=v1$getId(), `_to`=v2$getId())
}
\author{
Gabriele Galatolo, g.galatolo(at)kode.srl
}
