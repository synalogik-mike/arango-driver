% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/arango_documents.R
\name{document_set}
\alias{document_set}
\title{Update a document}
\usage{
document_set(.data, ...)
}
\arguments{
\item{.data}{the document to be updated}

\item{...}{new or updated assignment to be added to the given document}
}
\value{
the ArangoDocument updated but not yet consistent with the server image
}
\description{
Updates the attributes of the given document. When it is needed to made effective
the updates must be call the collection_update() function.
}
\author{
Gabriele Galatolo, g.galatolo(at)kode.srl
}
