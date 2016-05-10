\name{dataVAR1}
\alias{dataVAR1}
\title{
Sample data from a VAR(1) model
}
\description{
Sample data from a VAR(1) model.
}
\usage{
dataVAR1(n, T, A, SigmaE)
}
\arguments{
\item{n}{ Positive \code{numeric} of length one: number of individuals to be sampled. }
\item{T}{ Positive \code{numeric} of length one: number of time points (per individual) to be sampled. }
\item{A}{ A \code{Matrix} \eqn{\mathbf{A}} of regression parameters. }
\item{SigmaE}{ Covariance \code{matrix} of the errors (innovations). }
}
\value{
A three dimensional \code{array} containing the data. The first, second and third dimensions correspond to covariates, time and samples, respectively.
}
\author{
Wessel N. van Wieringen <w.vanwieringen@vumc.nl>
}
\seealso{
\code{\link{ridgeVAR1}}.
}
\examples{
# set dimensions
p <- 3; n <- 4; T <- 10

# set model parameters
SigmaE <- diag(p)/4
A <- createA(p, "chain")

# generate data
Y <- dataVAR1(n, T, A, SigmaE)
}

