loglikLOOCVcontourVAR1 <- function(lambdaAgrid, 
                                   lambdaPgrid, 
                                   Y, 
                                   figure=TRUE, 
                                   verbose=TRUE, 
                                   ...){

	########################################################################
	# 
	# DESCRIPTION:
	# Evaluates the leave-one-out cross-validated log-likelihood of the 
	# VAR(1) model for a given grid of the ridge penalty parameters 
	# (lambdaA and lambdaO). The result is plotted as a contour plot, which 
	# facilitates the choice of optimal penalty parameters. The functions 
	# also works with a (possibly) unbalanced experimental set-up. The 
	# VAR(1)-process is assumed to have mean zero.
	#
	# ARGUMENTS:
	# -> lambdaAgrid   : Numeric of length larger than one. It contains 
	#                    the grid points corresponding to the lambdaA.
	# -> lambdaPgrid   : Numeric of length larger than one. It contains 
	#                    the grid points corresponding to the lambdaO.
	# -> Y             : Three-dimensional array containing the data. 
	#                    The first, second and third dimensions 
	#                    correspond to covariates, time and samples, 
	#                    respectively. The data are assumed to centered 
	#                    covariate-wise.
	# -> figure        : Logical, indicating whether the contour plot 
	#                    should be generated.
	# -> verbose       : Logical indicator: should intermediate output be 
	#                    printed on the screen?
	# -> ...           : Other arguments to be passed to loglikLOOCVVAR1.
	#
	# DEPENDENCIES:
	# require("rags2ridges")          # functions from package : 
	#                                   loglikLOOCVVAR1
	#
	# NOTES:
	# ...
	#
	########################################################################

	# input checks
	if (!is(Y, "array")){ 
		stop("Input (Y) is of wrong class.") 
	}
	if (length(dim(Y)) != 3){ 
		stop("Input (Y) is of wrong dimensions: either covariate, time or sample dimension is missing.") 
	}
	if (!is(lambdaAgrid, "numeric")){ 
		stop("Input (lambdaAgrid) is of wrong class.") 
	}
	if (!is(lambdaPgrid, "numeric")){ 
		stop("Input (lambdaPgrid) is of wrong class.") 
	}
	if (length(lambdaAgrid) != length(unique(lambdaAgrid))){ 
		stop("Input (lambdaAgrid) contains non-unique values.") 
	}
	if (length(lambdaAgrid) < 2){ 
		stop("Input (lambdaAgrid) is of wrong length.") 
	}
	if (length(lambdaPgrid) != length(unique(lambdaPgrid))){ 
		stop("Input (lambdaPgrid) contains non-unique values.") 
	}
	if (length(lambdaPgrid) < 2){ 
		stop("Input (lambdaPgrid) is of wrong length.") 
	}
	if (any(is.na(lambdaAgrid))){ 
		stop("Input (lambdaAgrid) is not a vector of non-negative numbers.") 
	}
	if (any(is.na(lambdaPgrid))){ 
		stop("Input (lambdaPgrid) is not a vector of non-negative numbers.") 
	}
	if (any(lambdaAgrid <= 0)){ 
		stop("Input (lambdaAgrid) is not a vector of non-negative numbers.") 
	}
	if (any(lambdaPgrid <= 0)){ 
		stop("Input (lambdaPgrid) is not a vector of non-negative numbers.") 
	}
	if (!is(figure, "logical")){ 
		stop("Input (figure) is of wrong class.") 
	}
	if (!is(verbose, "logical")){ 
		stop("Input (verbose) is of wrong class.") 
	}

	# evaluate cross-validated log-likelihood at all grid points
	lambdaAgrid <- sort(lambdaAgrid)
	lambdaPgrid <- sort(lambdaPgrid)

	# should progress be reported?
	if (verbose){ 
		cat("grid point:", "\n") 
	}

	# evaluate cross-validated log-likelihood at all grid points
	llLOOCV <- matrix(NA, nrow=length(lambdaAgrid), 
	                      ncol=length(lambdaPgrid))
	for (kA in 1:length(lambdaAgrid)){
		for (kP in 1:length(lambdaPgrid)){
			if (verbose){ 
		        cat(rep("\b", 100), sep ="")
				cat(paste("lambdaA=", lambdaAgrid[kA], "; 
				           lambdaP=", lambdaPgrid[kP], sep=""))
			}
			llLOOCV[kA, kP] <- loglikLOOCVVAR1(c(lambdaAgrid[kA], 
			                                     lambdaPgrid[kP]), 
						             Y, ...)
        	}     
    	}

	# plot contour
	if (figure){
		contour(lambdaAgrid, 
		        lambdaPgrid, 
		        -llLOOCV, 
		        xlab="lambdaA", 
		        ylab="lambdaP", 
		        main="cross-validated log-likelihood")
	}

	# return cross-validated 
	return(list(lambdaA=lambdaAgrid, 
	            lambdaP=lambdaPgrid, 
	            llLOOCV=-llLOOCV))
}



