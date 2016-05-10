\name{impulseResponseVAR1}
\alias{impulseResponseVAR1}
\title{
Impulse response analysis of the VAR(1) model
}
\description{
Evaluate the mean absolute impulse responses of the VAR(1) model. It assesses the effect of an innovation (error) at one time point on the 
variates at future time points. In the VAR(1) model this amounts to studying powers of \eqn{\mathbf{A}}, the matrix of regression coefficients. 
}
\usage{
impulseResponseVAR1(A, Tmax, figure=FALSE)
}
\arguments{
\item{A}{ A \code{matrix} \eqn{\mathbf{A}} of regression parameters. }
\item{Tmax}{ Maximum number (positive \code{numeric} of length one) of time points up to which the impulse responses are to be evaluated. }
\item{figure}{ A \code{logical}, indicating whether a summary plot of the impulse responses should be generated. }
}
\value{
Object of class \code{matrix}. Rows correspond to covariates, columns to time points, and elements to the column-mean of the absolute impulse responses. 
}
\references{
Hamilton, J. D. (1994), Time series analysis. Princeton: Princeton university press.

Lutkepohl, H. (2005), New Introduction to Multiple Time Series Analysis. Springer, Berlin.
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
impulseResponseVAR1(VAR1hat$A, 10, figure=TRUE)
}

