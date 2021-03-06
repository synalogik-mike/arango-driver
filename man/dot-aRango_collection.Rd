% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/arango_collection.R
\docType{data}
\name{.aRango_collection}
\alias{.aRango_collection}
\title{An ArangoCollection is a class where instances are used to handle the interaction with
real collections on the server.}
\format{An object of class \code{R6ClassGenerator} of length 24.}
\usage{
.aRango_collection
}
\arguments{
\item{name}{the name of the collection}

\item{waitForSync}{(from Arango doc) if true then the data is synchronized to disk before returning from a 
document create, update, replace or removal.}

\item{isSystem}{(from Arango doc) if true creates a system collection. In this case name SHOULD start 
with an underscore}

\item{type}{(from Arango doc) the type of the collection to create. The following values are valid,
collection_type$DOCUMENT or collection_type$EDGE}
}
\value{
the name of the collection handled by this object

TRUE iff this object handles a system collection, FALSE otherwise

the number of the element of this collection
}
\description{
An ArangoCollection is a class where instances are used to handle the interaction with
real collections on the server.
}
\seealso{
collection_status enumeration

collection_type enumeration
}
\author{
Gabriele Galatolo, g.galatolo(at)kode.srl
Creates a new collection belonging to an existing database in the server

Gabriele Galatolo, g.galatolo(at)kode.srl
Returns the name of the collection handled by this object

Gabriele Galatolo, g.galatolo(at)kode.srl
Returns TRUE iff this object handles a system collection, FALSE otherwise

Gabriele Galatolo, g.galatolo(at)kode.srl
Returns the identifier of the collection

Gabriele Galatolo, g.galatolo(at)kode.srl
Returns the status of the collection

Gabriele Galatolo, g.galatolo(at)kode.srl
Returns the number of the element of this collection

Gabriele Galatolo, g.galatolo(at)kode.srl
Returns the type of the collection

Gabriele Galatolo, g.galatolo(at)kode.srl
}
\keyword{datasets}
