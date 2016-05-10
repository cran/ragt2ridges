\name{sparsifyVAR1}
\alias{sparsifyVAR1}
\title{
Function that determines the null and non-null elements of \eqn{\mathbf{A}}
}
\description{
Function that determines the null and non-null elements of \eqn{\mathbf{A}}, the matrix of regression coefficients. 
}
\usage{
sparsifyVAR1(A, SigmaE, threshold=c("absValue", "localFDR", "top"), 
absValueCut=0.25, FDRcut=0.8, top=10, statistics=FALSE, verbose=FALSE)
}
\arguments{
\item{A}{ \code{Matrix} \eqn{\mathbf{A}} of regression parameters. }
\item{SigmaE}{ Covariance \code{matrix} of the errors (innovations). }
\item{threshold}{ A \code{character} signifying type of sparsification of \eqn{\mathbf{A}} by thresholding. Must be one of: "absValue", "localFDR", or "top". }
\item{absValueCut}{ A \code{numeric} giving the cut-off for element selection based on absolute value thresholding. }
\item{FDRcut}{ A \code{numeric} giving the cut-off for element selection based on local false discovery rate (FDR) thresholding. }
\item{top}{ A \code{numeric} giving the number of elements of \eqn{\code{A}} which is to be selected, based on absolute value thresholding. }
\item{statistics}{ A \code{logical} indicator: should test statistics be returned. This only applies when 
\code{threshold = "localFDR"}}
\item{verbose}{ A \code{logical} indicator: should intermediate output be printed on the screen? }
}
\value{
A \code{list}-object with slots:
\item{zeros}{ A \code{matrix} with indices of entries of \eqn{\mathbf{A}} that are identified to be null. }
\item{nonzeros}{ A \code{matrix} with indices of entries of \eqn{\mathbf{A}} that are identified to be non-null. }
\item{statistics}{ A \code{matrix} with test statistics employed in the local FDR procedure. }
The matrices \code{zeros} and \code{nonzeros} comprise two columns, each row corresponding to an entry of \eqn{\mathbf{A}}. The first column contains the row indices and the second the column indices.
}
\details{
When \code{threshold = "localFDR"} the function divides the elements of (possibly regularized) input matrix \eqn{\mathbf{A}} of regression coefficients by their standard errors. Subsequently, the support of the matrix \eqn{\mathbf{A}} is determined by usage of local FDR. In that case a mixture model is fitted to the nonredundant (standardized) elements of \eqn{\mathbf{A}} by \code{fdrtool}. The decision to retain elements is then based on the argument \code{FDRcut}. Elements with a posterior probability \eqn{>=q}  \code{FDRcut} (equalling 1 - local FDR) are retained. See Strimmer (2008) for further details. Alternatively, the support of \eqn{\mathbf{A}} is determined by simple thresholding on the absolute values of matrix entries (\code{threshold = "absValue"}). A third option (\code{threshold = "top"}) is to retain a prespecified number of matrix entries based on absolute values of the elements of \eqn{\mathbf{A}}. For example, one could wish to retain those
entries representing the ten strongest cross-temporal coefficients. 
     
The argument \code{absValueCut} is only used when \code{threshold = "absValue"}. The argument \code{FDRcut} is only used when \code{threshold = "localFDR"}. The argument \code{top} is only used when \code{threshold = "top"}. 
}
\references{
Strimmer, K. (2008), "fdrtool: a versatile R package for estimating local and tail area-based false discovery rates", \emph{Bioinformatics} 24(12): 1461-1462.

Van Wieringen, W.N., Peeters, C.F.W. (2014), "Ridge Estimation of Inverse Covariance Matrices from High-Dimensional Data", arXiv:1403.0904 [stat.ME].

Miok, V., Wilting, S.M., Van Wieringen, W.N. (2015), "Ridge estimation of the VAR(1) model and its time series chain graph from multivariate time-course omics data", submitted. 
}
\author{
Wessel N. van Wieringen <w.vanwieringen@vumc.nl>, Carel F.W. Peeters.
}
\seealso{
\code{\link{ridgeVAR1}}, \code{\link[rags2ridges:sparsify]{sparsify}}.
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

## determine which elements of A are non-null
\dontrun{ Anullornot <- matrix(0, p, p) }
\dontrun{ Anullornot[sparsifyVAR1(VAR1hat$A, solve(VAR1hat$P), 
threshold="localFDR")$nonzeros] <- 1 }
## REASON FOR NOT RUN:
## the employed local FDR approximation is only valid for reasonably sized 
## number of elements of A (say) at least p > 10 and, 
## consequently, a vector of 100 regression coefficients.

## plot non-null structure of A 
\dontrun{ edgeHeat(Anullornot) }
}

