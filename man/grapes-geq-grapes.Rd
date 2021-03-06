% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/arango_common_operators.R
\name{\%geq\%}
\alias{\%geq\%}
\title{Comparison >= operator for aRangodb::collection_filter()}
\usage{
expr \%geq\% value
}
\arguments{
\item{expr}{the expression to be left as given in the resulting string}

\item{value}{the expression to be evaluated and printed in the resulting string}
}
\description{
Creates a string expression representing an AQL filter "greater or equal than" clause for
numeric values
}
\examples{
age \%geq\% 33 gives "age >= 33" 

}
\author{
Gabriele Galatolo, g.galatolo(at)kode.srl
}
