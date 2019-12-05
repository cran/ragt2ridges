ridgeVAR1fused <- function(Y, 
                           id, 
                           lambdaA=0, 
                           lambdaF=0, 
                           lambdaP=0, 
                           targetA=matrix(0, dim(Y)[1], dim(Y)[1]), 
                           targetP=matrix(0, dim(Y)[1], dim(Y)[1]), 
                           targetPtype="none", 
                           fitA="ml", 
                           zerosA=matrix(nrow=0, ncol=2), 
                           zerosAfit="sparse", 
                           zerosP=matrix(nrow=0, ncol=2), 
                           cliquesP=list(), 
                           separatorsP=list(), 
                           unbalanced=matrix(nrow=0, ncol=2), 
                           diagP=FALSE, 
                           efficient=TRUE, 
                           nInit=100, 
                           nInitA=5, 
                           minSuccDiff=0.001, 
                           minSuccDiffA=0.001){
	########################################################################
	# 
	# DESCRIPTION: 
	# Ridge estimation of the parameters of the VAR(1) model. The 
	# log-likelihood is augmented with a ridge penalty for both parameters, 
	# A, the matrix of regression coefficients, and 
	# SigmaE, the inverse of the error variance. 
	# 
	# ARGUMENTS:
	# -> Y             : Three-dimensional array containing the data. The 
	#                    first, second and third dimensions correspond to 
	#                    covariates, time and samples, respectively. The 
	#                    data are assumed to centered covariate-wise.
	# -> id            : A vector with groups indices comprising of integers 
	#                    only. First group is represented by '0', the next
	#                    by '1', and so on until the last.
	# -> lambdaA       : Ridge penalty parameter to be used in the 
	#                    estimation of the As, the matrices with 
	#                    autoregression coefficients.
	# -> lambdaF       : Fused ridge penalty parameter to be used in the 
	#                    estimation of the As, the matrices with 
	#                    autoregression coefficients.	
	# -> lambdaP       : Ridge penalty parameter to be used in the estimation
	#                    of Omega, the precision matrix of the errors.
	# -> targetA       : Target matrix to which the matrix A is to be 
	#                    shrunken. Note this target is shared among the
	#                    groups (otherwise why fuse?)
	# -> targetP       : Target matrix to which the precision matrix Omega
	#                    is to be shrunken.
	# -> zerosA        : Matrix with indices of entries of A that are 
	#                    constrained to zero. The matrix comprises two 
	#                    columns, each row corresponding to an entry of A. 
	#                    The first column contains the row indices and the 
	#                    second the column indices.
	#                    Note the support is shared among the groups 
	#                    (otherwise why fuse?)
	# -> zerosAfit     : Character, either "sparse" or "dense". With 
	#                    "sparse", the matrix A is assumed to contain many 
	#                    zeros and a computational efficient implementation
	#                    of its estimation is employed. If "dense", it is 
	#                    assumed that A contains 
	#                    only few zeros and the estimation method is 
	#                    optimized computationally accordingly.
	# -> zerosP        : A matrix with indices of entries of the precision 
	#                    matrix that are constrained to zero. The matrix 
	#                    comprises two columns, each row corresponding to 
	#                    an entry of the adjacency matrix. The first column
	#                    contains the row indices and the second the column
	#                    indices. The specified graph should be undirected 
	#                    and decomposable. If not, it is symmetrized and 
	#                    triangulated (unless cliquesP and seperatorsP are 
	#                    supplied). Hence, the employed zero structure may 
	#                    differ from the input 'zerosP'.
	# -> cliquesP      : A 'list'-object containing the node indices per 
	#                    clique as object from the 'rip-function.
	# -> separatorsP   : A 'list'-object containing the node indices per 
	#                    clique as object from the 'rip-function.
	# -> unbalanced    : A matrix with two columns, indicating the 
	#                    unbalances in the design. Each row represents a 
	#                    missing design point in the (time x individual)-
	#                    layout. The first and second column indicate the 
	#                    time and individual (respectively) specifics of 
	#                    the missing design point.
	# -> diagP         : Logical, indicates whether the error covariance 
	#                    matrix is assumed to be diagonal.
	# -> efficient     : Logical, affects estimation of A. Details below.
	# -> nInit         : Maximum number of iterations to used in maximum 
	#                    likelihood estimation.
	# -> nInitA        : Maximum number of iterations to used in inner 
	#                    iterative estimation of A.	
	# -> minSuccDiff   : Minimum distance between estimates of two 
	#                    successive iterations to be achieved.
	# -> minSuccDiffA  : Minimum distance between estimates of two 
	#                    successive iterations to be achieved in the inner 
	#                    iterative estimation of A.	
	# 
	# DEPENDENCIES:
	# library(rags2ridges)	    # functions: default.target, 
	#                             ridgeP, ridgePchordal. 
	#                             Former two may called on the C++-side.
	#
	# NOTES:
	# ....
	# 
	#######################################################################

	# input checks
	if (!is(Y, "array")){ 
		stop("Input (Y) is of wrong class.") 
	}
	if (length(dim(Y)) != 3){ 
		stop("Input (Y) is of wrong dimensions: either covariate, time or sample dimension is missing.") 
	}
	if (!is(id, "numeric") & !is(id, "integer")){ 
		stop("Input (id) is of wrong class.") 
	}
	if (length(id) != dim(Y)[3]){ 
		stop("Input (id) is of wrong length: should equal sample dimension of Y.") 
	}
	if (!is(lambdaA, "numeric")){ 
		stop("Input (lambdaA) is of wrong class.") 
	}
	if (length(lambdaA) != 1){ 
		stop("Input (lambdaA) is of wrong length.") 
	}
	if (is.na(lambdaA)){ 
		stop("Input (lambdaA) is not a non-negative number.") 
	}
	if (lambdaF < 0){ 
		stop("Input (lambdaF) is not a non-negative number.") 
	}
	if (!is(lambdaF, "numeric")){ 
		stop("Input (lambdaF) is of wrong class.") 
	}
	if (length(lambdaF) != 1){ 
		stop("Input (lambdaF) is of wrong length.") 
	}
	if (is.na(lambdaF)){ 
		stop("Input (lambdaF) is not a non-negative number.") 
	}
	if (lambdaF < 0){ 
		stop("Input (lambdaF) is not a non-negative number.") 
	}
	if (!is(lambdaP, "numeric")){ 
		stop("Input (lambdaP) is of wrong class.") 
	}
	if (length(lambdaP) != 1){ 
		stop("Input (lambdaP) is of wrong length.") 
	}
	if (is.na(lambdaP)){ 
		stop("Input (lambdaP) is not a non-negative number.") 
	}
	if (lambdaP < 0){ 
		stop("Input (lambdaP) is not a non-negative number.") 
	}
	if (!is.null(unbalanced) & !is(unbalanced, "matrix")){ 
		stop("Input (unbalanced) is of wrong class.") 
	}    
	if (!is.null(unbalanced)){ 
		if(ncol(unbalanced) != 2){ 
			stop("Wrong dimensions of the matrix unbalanced.") 
		} 
	} 
	if (!is(zerosAfit, "character")){ 
		stop("Input (zerosAfit) is of wrong class.") 
	}
	if (!is(zerosAfit, "character")){ 
		if (!(zerosAfit %in% c("dense", "sparse"))){ 
			stop("Input (zerosAfit) ill-specified.") 
		} 
	}
	if (!is(diagP, "logical")){ 
		stop("Input (diagP) is of wrong class.") 
	}
	if (!is(efficient, "logical")){ 
		stop("Input (efficient) is of wrong class.") 
	}
	if (!is(nInit, "numeric") & !is(nInit, "logical")){ 
		stop("Input (nInit) is of wrong class.") 
	}
	if (length(nInit) != 1){ 
		stop("Input (nInit) is of wrong length.") 
	}
	if (is.na(nInit)){ 
		stop("Input (nInit) is not a positive integer.") 
	}
	if (nInit < 0){ 
		stop("Input (nInit) is not a positive integer.") 
	}
	if (!is(nInitA, "numeric") & !is(nInitA, "logical")){ 
		stop("Input (nInitA) is of wrong class.") 
	}
	if (length(nInitA) != 1){ 
		stop("Input (nInitA) is of wrong length.") 
	}
	if (is.na(nInitA)){ 
		stop("Input (nInitA) is not a positive integer.") 
	}
	if (nInitA < 0){ 
		stop("Input (nInitA) is not a positive integer.") 
	}
	if (!is(minSuccDiff, "numeric")){ 
		stop("Input (minSuccDiff) is of wrong class.") 
	}
	if (length(minSuccDiff) != 1){ 
		stop("Input (minSuccDiff) is of wrong length.") 
	}
	if (is.na(minSuccDiff)){ 
		stop("Input (minSuccDiff) is not a positive number.") 
	}
	if (minSuccDiffA <= 0){ 
		stop("Input (minSuccDiffA) is not a positive number.") 
	}
	if (!is(minSuccDiffA, "numeric")){ 
		stop("Input (minSuccDiffA) is of wrong class.") 
	}
	if (length(minSuccDiffA) != 1){ 
		stop("Input (minSuccDiffA) is of wrong length.") 
	}
	if (is.na(minSuccDiffA)){ 
		stop("Input (minSuccDiffA) is not a positive number.") 
	}
	if (minSuccDiffA <= 0){ 
		stop("Input (minSuccDiffA) is not a positive number.") 
	}
	if (!is.null(targetA) & !is(targetA, "matrix")){ 
		stop("Input (targetA) is of wrong class.") 
	}
	if (is.null(targetP)){ 
		targetP <- "Null" 
	}    
	if (!is.null(targetP) & (!is(targetP, "matrix") & !is(targetP, "character"))){ 
		stop("Input (targetP) is of wrong class.") 
	}    
	if (!is.null(targetP) & is(targetP, "matrix")){ 
		if(!isSymmetric(targetP)){ 
			stop("Non-symmetrical target for the precision matrix provided") 
		} 
	} 
	if (diagP & !is.null(targetP) &  is(targetP, "matrix")){ 
		if(max(abs(upper.tri(targetP))) != 0){ 
			stop("Inconsistent input (targetP v. diagP) provided") 
		} 
	}
	if (!is.null(targetP) & is(targetP, "character")){ 
		if( length(intersect(targetP, c("DAIE", "DIAES", "DUPV", "DAPV", "DCPV", "DEPV", "Null"))) != 1 ){ 
			stop("Wrong default target for the precision matrix provided: see default.target for the options.") 
		} 
	} 
	if (!is.null(targetA)){ 
		if (dim(Y)[1] != nrow(targetA)){ 
			stop("Dimensions of input (targetA) do not match that of other input (Y).") 
		} 
	}
	if (!is.null(targetA)){ 
		if (dim(Y)[1] != ncol(targetA)){ 
			stop("Dimensions of input (targetA) do not match that of other input (Y).") 
		} 
	}
	if (!is.null(targetP) & !is(targetP, "matrix")){ 
		if (dim(Y)[1] != nrow(targetP)){ 
			stop("Dimensions of input (targetP) do not match that of other input (Y).") 
		} 
	}
	if (!is.null(zerosA) & !is(zerosA, "matrix")){ 
		stop("Input (zerosA) is of wrong class.") 
	}    
	if (!is.null(zerosA)){ 
		if(ncol(zerosA) != 2){ 
			stop("Wrong dimensions of the (zerosA) matrix.") 
		} 
	} 
	if (!is.null(zerosA)){ 
		zerosA <- zerosA[order(zerosA[,2], zerosA[,1]),] 
	}
	if (!is.null(zerosP) & !is(zerosP, "matrix")){ 
		stop("Input (zerosP) is of wrong class.") 
	}    
	if (!is.null(zerosP)){ 
		if(ncol(zerosP) != 2){ 
			stop("Wrong dimensions of the (zerosP).") 
		} 
	} 
	if (!is.null(zerosP)){ 
		zerosP <- zerosP[order(zerosP[,2], zerosP[,1]),] 
	}

	# extract number of variates
	p <- nrow(Y)

	# target only appears in a product with lambdaA. 
	# moreover, the multiplication of a matrix times a scaler is faster in R.
	targetA <- lambdaA * targetA;

	# estimation without support information on P
	if (nrow(zerosP) == 0){
		VAR1hat <- .armaVAR1fused_ridgeML(Y, 
		                                  id, 
		                                  lambdaA, 
		                                  lambdaF, 
		                                  lambdaP, 
		                                  targetA, 
		                                  targetP, 
		                                  targetPtype, 
		                                  fitA, 
		                                  unbalanced, 
		                                  diagP, 
		                                  efficient, 
		                                  zerosA[,1], 
		                                  zerosA[,2], 
		                                  zerosAfit, 
		                                  nInit, 
		                                  nInitA, 
		                                  minSuccDiff, 
		                                  minSuccDiffA);
 		Phat <- VAR1hat$P; 
		Ahats <- VAR1hat$As; 
		LL <- VAR1hat$LL;
	}	

	# estimation with support information both on A and on P
	if (nrow(zerosP) > 0){
		if (fitA == "ss"){
	        	# set profiles of missing (time, sample)-points to missing
			if (!is.null(unbalanced)){ 
				Y <- .armaVAR_array2cube_withMissing(Y, 
				                                     unbalanced[,1], 
				                                     unbalanced[,2]); 
			}

			# initial estimate As by SS minimization and store as a long matrix
			VARYs <- COVYs <- Ahats <- matrix(nrow=0, ncol=dim(Y)[1])
			for (g in 0:max(id)){           
				VARYs <- rbind(VARYs, .armaVAR1_VARYhat(Y[,,which(id == g), drop=FALSE], 
				                                        efficient, 
				                                        unbalanced));
				COVYs <- rbind(COVYs, .armaVAR1_COVYhat(Y[,,which(id == g), drop=FALSE]));
				Ahats <- rbind(Ahats, .armaVAR1_Ahat_ridgeSS(VARYs[c((p*g+1):(p*(g+1))),], 
				                                             COVYs[c((p*g+1):(p*(g+1))),], 
				                                             lambdaA, 
				                                             targetA));
			}

			# eigenvalue decompositions of groups-wise process variance estimates
			eigDecomps <- .armaEigenDecomp_stackedCovariances(VARYs);    
	
			# estimate As in fused fashion
			Ahats <- .armaVAR1fused_Ahat(Ahats, 
			                             diag(nrow(Y)), 
			                             COVYs, 
			                             eigDecomps[[2]], 
			                             eigDecomps[[1]], 
			                             lambdaA, 
			                             lambdaF, 
			                             targetA, 
			                             fitA, 
			                             zerosA[,1], 
			                             zerosA[,2], 
			                             zerosAfit, 
			                             nInitA, 
			                             minSuccDiffA);

			# calculate Se and estimate precision
			Se <- .armaVAR1fused_Shat_ML(Y, Ahats, id);

			# if cliques and separators of support of P are not provided:
			if (length(cliquesP)==0){
				supportPinfo <- support4ridgeP(zeros=zerosP, 
				                               nNodes=dim(Y)[1]);
				cliquesP     <- supportPinfo$cliques; 
				separatorsP  <- supportPinfo$separators; 
				zerosP       <- supportPinfo$zeros;
			}
	
			# ridge ML estimation of Se
			if (is.character(targetP)){ 
				target <- .armaP_defaultTarget(Se, 
				                               targetType=targetPtype, 
				                               fraction=0.0001, 
				                               multiplier=0);
			} else { 
				target <- targetP; 
			}
			Phat <- ridgePchordal(Se, 
			                      lambda=lambdaP, 
			                      target=target, 
			                      zeros=zerosP, 
			                      cliques=cliquesP, 
			                      separators=separatorsP, 
			                      type="Alt", 
			                      verbose=FALSE);
		}
        	if (fitA == "ml"){
			# set profiles of missing (time, sample)-points to missing
			if (!is.null(unbalanced)){ 
				Y <- .armaVAR_array2cube_withMissing(Y, unbalanced[,1], unbalanced[,2]); 
			}

			# initial estimate As by SS minimization and store as a long matrix
			VARYs <- COVYs <- Ahats <- matrix(nrow=0, ncol=dim(Y)[1]);
			for (g in 0:max(id)){           
				VARYs <- rbind(VARYs, .armaVAR1_VARYhat(Y[,,which(id == g), drop=FALSE], 
				                                        efficient, 
				                                        unbalanced));
				COVYs <- rbind(COVYs, .armaVAR1_COVYhat(Y[,,which(id == g), drop=FALSE]));
				Ahats <- rbind(Ahats, .armaVAR1_Ahat_ridgeSS(VARYs[c((p*g+1):(p*(g+1))),], 
				                                             COVYs[c((p*g+1):(p*(g+1))),], 
				                                             lambdaA, 
				                                             targetA));
			}

			# eigenvalue decompositions of groups-wise process variance estimates
			eigDecomps <- .armaEigenDecomp_stackedCovariances(VARYs);    

			# calculate Se and estimate precision
			Se <- .armaVAR1fused_Shat_ML(Y, Ahats, id);
		
			# if cliques and separators of support of P are not provided:
			if (length(cliquesP)==0){
				supportPinfo <- support4ridgeP(zeros=zerosP, 
				                               nNodes=dim(Y)[1]);
				cliquesP     <- supportPinfo$cliques; 
				separatorsP  <- supportPinfo$separators; 
				zerosP       <- supportPinfo$zeros;
			}
	
			# ridge ML estimation of Se
			if (is.character(targetP)){ 
				target <- .armaP_defaultTarget(Se, 
				                               targetType=targetPtype, 
				                               fraction=0.0001, 
				                               multiplier=0);
			} else { 
				target <- targetP;
			}
			Phat <- ridgePchordal(Se, 
			                      lambda=lambdaP, 
			                      target=target, 
			                      zeros=zerosP, 
			                      cliques=cliquesP, 
			                      separators=separatorsP, 
			                      type="Alt", 
			                      verbose=FALSE);

			#######################################################
			# estimate parameters by ML, using the SS estimates as 
			# initials
			#######################################################

			for (u in 1:nInit){
				# store latest estimates
				Aprevs <- Ahats; 
				Pprev <- Phat;

				# estimate As in fused fashion
				Ahats <- .armaVAR1fused_Ahat(Ahats, 
				                             Phat, 
				                             COVYs, 
				                             eigDecomps[[2]], 
				                             eigDecomps[[1]], 
				                             lambdaA, 
				                             lambdaF, 
				                             targetA, 
				                             fitA, 
				                             zerosA[,1], 
				                             zerosA[,2], 
				                             zerosAfit, 
				                             nInitA, 
				                             minSuccDiffA);

				# calculate Se
				Se <- .armaVAR1fused_Shat_ML(Y, Ahats, id);

				# ridge ML estimation of Se
				if (is.character(targetP)){ 
					target <- .armaP_defaultTarget(Se, 
					                               targetType=targetPtype, 
					                               fraction=0.0001, 
					                               multiplier=0) 
				} else { 
					target <- targetP 
				}
				Phat <- ridgePchordal(Se, 
				                      lambda=lambdaP, 
				                      target=target, 
				                      zeros=zerosP, 
				                      cliques=cliquesP, 
				                      separators=separatorsP, 
				                      type="Alt", 
				                      verbose=FALSE);

				# assess convergence
				if (.armaVAR1fused_convergenceEvaluation(Ahats, Aprevs, Phat, Pprev) < minSuccDiff){ 
					break 
				}
			}
	    	}
	}

	# evaluate likelihood
	LL <- 0
	for (g in 0:max(id)){           
		Se <- .armaVAR1_Shat_ML(Y[, , which(id == g), drop=FALSE], 
		                        Ahats[c((p*g+1):(p*(g+1))),, drop=FALSE]);
		LL <- LL + (dim(Y)[2] - 1) * sum(id==g) * (determinant(Phat)$modulus - sum(Se * Phat)) / 2;    	
	}

	return(list(As=Ahats, P=Phat, LL=LL, lambdaA=lambdaA, lambdaF=lambdaF, lambdaP=lambdaP))
}

