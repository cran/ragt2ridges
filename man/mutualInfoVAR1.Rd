\name{mutualInfoVAR1}
\alias{mutualInfoVAR1}
\title{
Mutual information analysis of the VAR(1) model
}
\description{
Evaluate, within the VAR(1) model, the mutual information between a variate at one time point and the variates at future time points.
}
\usage{
mutualInfoVAR1(A, SigmaE, Tmax, figure=FALSE)
}
\arguments{
\item{A}{ A \code{matrix} \eqn{\mathbf{A}} of auto-regression parameters. }
\item{SigmaE}{ Covariance \code{matrix} of the errors (innovations). }
\item{Tmax}{ Maximum number (positive \code{numeric} of length one) of time points up to which the mutual informations are to be evaluated. }
\item{figure}{ A \code{logical}, indicating whether a summary plot of the mutual informations should be generated. }
}
\value{
Object of class \code{matrix}. Rows correspond to covariates, columns to time points, and elements to the mutual informations. 
}
\references{
Miok, V., Wilting, S.M., Van Wieringen, W.N. (2015), "Ridge estimation of the VAR(1) model and its time series chain graph from multivariate time-course omics data", submitted. 
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

# fit VAR(1) model
VAR1hat <- ridgeVAR1(Y, 1, 1)

# impulse response analysis
mutualInfoVAR1(VAR1hat$A, solve(symm(VAR1hat$P)), 10, figure=TRUE)
}

