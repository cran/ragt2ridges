ridgeVARX1 <- function(Y, 
		       X, 
		       lambdaA=-1, 
		       lambdaB=-1, 
		       lambdaP=-1, 
		       lagX, 
		       targetA=matrix(0, dim(Y)[1], dim(Y)[1]), 
		       targetB=matrix(0, dim(Y)[1], dim(X)[1]), 
		       targetP=matrix(0, dim(Y)[1], dim(Y)[1]), 
		       targetPtype="none", 
		       fitAB="ml", 
		       zerosA=matrix(nrow=0, ncol=2), 
		       zerosB=matrix(nrow=0, ncol=2), 
		       zerosAfit="sparse", 
		       zerosBfit="sparse", 
		       zerosP=matrix(nrow=0, ncol=2), 
		       cliquesP=list(), 
		       separatorsP=list(), 
		       unbalanced=matrix(nrow=0, ncol=2), 
		       diagP=FALSE, 
		       efficient=TRUE, 
		       nInit=100, 
		       minSuccDiff=0.001){

	########################################################################
	# 
	# DESCRIPTION: 
	# Ridge estimation of the parameters of the VARX(1) model. The 
	# log-likelihood is augmented with a ridge penalty for all three 
	# parameters, A, the matrix of auto-regression coefficients, B, the 
	# matrix with regression coefficient of the time-varying covariates, 
	# and OmegaE, the inverse of the error variance. 
	# 
	# ARGUMENTS:
	# -> Y             : Three-dimensional array containing the data. The 
	#                    first, second and third dimensions correspond to 
	#                    covariates, time and samples, respectively. The 
	#                    data are assumed to centered covariate-wise.
	# -> lambdaA       : Ridge penalty parameter to be used in the 
	#                    estimation of A, the matrix with autro-regressive 
	#                    coefficients.
	# -> lambdaB       : Ridge penalty parameter to be used in the 
	#                    estimation of B, the matrix with regression 
	#                    coefficients.
	# -> lambdaP       : Ridge penalty parameter to be used in the 
	#                    estimation of Omega, the precision matrix of the 
	#                    errors.
	# -> targetA       : Target matrix to which the matrix A is to be 
	#                    shrunken.
	# -> targetB       : Target matrix to which the matrix A is to be 
	#                    shrunken.
	# -> targetP       : Target matrix to which the precision matrix Omega
	#                    is to be shrunken.
	# -> zerosA        : Matrix with indices of entries of A that are 
	#                    constrained to zero. The matrix comprises two 
	#                    columns, each row corresponding to an entry of A.
	#                    The first column contains the row indices and the 
	#                    second the column indices.
	# -> zerosB        : Matrix with indices of entries of B that are 
	#                    constrained to zero. The matrix comprises two 
	#                    columns, each row corresponding to an entry of B. 
	#                    The first column contains the row indices and the 
	#                    second the column indices.
	# -> zerosAfit     : Character, either "sparse" or "dense". With 
	#                    "sparse", the matrix A is assumed to contain many 
	#                    zeros and a computational efficient implementation 
	#                    of its estimation is employed. If "dense", it is 
	#                    assumed that A contains only few zeros and the 
	#                    estimation method is optimized computationally 
	#                    accordingly.
	# -> zerosBfit     : Character, either "sparse" or "dense". With 
	#                    "sparse", the matrix B is assumed to contain many 
	#                    zeros and a computational efficient implementation 
	#                    of its estimation is employed. If "dense", it is 
	#                    assumed that B contains only few zeros and the 
	#                    estimation method is optimized computationally 
	#                    accordingly.
	# -> zerosP        : A matrix with indices of entries of the precision 
	#                    matrix that are constrained to zero. The matrix 
	#                    comprises two columns, each row corresponding to an
	#                    entry of the adjacency matrix. The first column 
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
	#                    unbalances in the design. Each row represents 
	#                    a missing design point in the (time x individual)-
	#                    layout. The first and second column indicate the 
	#                    time and individual (respectively) specifics of the 
	#                    missing design point.
	# -> diagP         : Logical, indicates whether the error covariance 
	#                    matrix is assumed to be diagonal.
	# -> efficient     : Logical, affects estimation of A. Details below.
	# -> nInit         : Maximum number of iterations to used in maximum 
	#                    likelihood estimation.
	# -> minSuccDiff   : Minimum distance between estimates of two 
	#                    successive iterations to be achieved.
	# 
	# DEPENDENCIES:
	# library(rags2ridges)	    # functions: default.target, ridgeP, 
	#                                        ridgePchordal. Former two may
	#                                        be called on the C++-side only.
	#
	# NOTES:
	# ....
	# 
	########################################################################

	# input checks
	if (!is(Y, "array")){ 
		stop("Input (Y) is of wrong class.") 
	}
	if (length(dim(Y)) != 3){ 
		stop("Input (Y) is of wrong dimensions: either covariate, time or sample dimension is missing.") 
	}
	if (!is(X, "array")){ 
		stop("Input (X) is of wrong class.") 
	}
	if (length(dim(X)) != 3){ 
		stop("Input (X) is of wrong dimensions: either covariate, time or sample dimension is missing.") 
	}
	if (any(dim(Y)[2:3] != dim(X)[2:3])){ 
		stop("Input (X) do not have same dimensions as Y.") 
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
	if (lambdaA < 0){ 
		stop("Input (lambdaA) is not a non-negative number.") 
	}
	if (!is(lambdaB, "numeric")){ 
		stop("Input (lambdaB) is of wrong class.") 
	}
	if (length(lambdaB) != 1){ 
		stop("Input (lambdaB) is of wrong length.") 
	}
	if (is.na(lambdaB)){ 
		stop("Input (lambdaB) is not a non-negative number.") 
	}
	if (lambdaB < 0){ 
		stop("Input (lambdaB) is not a non-negative number.") 
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
	if (is(zerosAfit, "character")){ 
		if (!(zerosAfit %in% c("dense", "sparse"))){ 
			stop("Input (zerosAfit) ill-specified.") 
		} 
	}
	if (!is(zerosBfit, "character")){ 
		stop("Input (zerosBfit) is of wrong class.") 
	}
	if (is(zerosBfit, "character")){ 
		if (!(zerosBfit %in% c("dense", "sparse"))){ 
			stop("Input (zerosBfit) ill-specified.") 
		} 
	}
	if (!is(diagP, "logical")){ 
		stop("Input (diagP) is of wrong class.") 
	}
	if (!is(efficient, "logical")){ 
		stop("Input (efficient) is of wrong class.") 
	}
	if (!is(nInit, "numeric")){ 
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
	if (!is(minSuccDiff, "numeric")){ 
		stop("Input (minSuccDiff) is of wrong class.") 
	}
	if (length(minSuccDiff) != 1){ 
		stop("Input (minSuccDiff) is of wrong length.") 
	}
	if (is.na(minSuccDiff)){ 
		stop("Input (minSuccDiff) is not a positive number.") 
	}
	if (minSuccDiff <= 0){ 
		stop("Input (minSuccDiff) is not a positive number.") 
	}
	if (!is(targetA, "matrix")){ 
		stop("Input (targetA) is of wrong class.") 
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
	if (!is(targetB, "matrix")){ 
		stop("Input (targetB) is of wrong class.") 
	}
	if (!is.null(targetB)){ 
		if (dim(Y)[1] != nrow(targetB)){ 
			stop("Dimensions of input (# rows of targetB) do not match that of other input (# covariates of Y).") 
		} 
	}
	if (!is.null(targetB)){ 
		if (dim(X)[1] != ncol(targetB)){ 
			stop("Dimensions of input (# columns of targetB) do not match that of other input (# covariates of X).") 
		} 
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
	if (diagP & !is.null(targetP) & is(targetP, "matrix")){ 
		if(max(abs(upper.tri(targetP))) != 0){ 
			stop("Inconsistent input (targetP v. diagP) provided") 
		} 
	}
	if (!is.null(targetP) & is(targetP, "character")){ 
		if( length(intersect(targetP, c("DAIE", "DIAES", "DUPV", "DAPV", "DCPV", "DEPV", "Null"))) != 1 ){ 
			stop("Wrong default target for the precision matrix provided: see default.target for the options.") 
		} 
	} 
	if (!is.null(targetP) & is(targetP, "matrix")){ 
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
	if (!is.null(zerosB) & !is(zerosB, "matrix")){ 
		stop("Input (zerosB) is of wrong class.") 
	}    
	if (!is.null(zerosB)){ 
		if(ncol(zerosB) != 2){ 
			stop("Wrong dimensions of the (zerosB) matrix.") 
		} 
	} 
	if (!is.null(zerosB)){ 
		zerosB <- zerosB[order(zerosB[,2], zerosB[,1]),] 
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

	# targets only appears in a product with lambdas. 
	# moreover, the multiplication of a matrix times a scaler is faster in R.
	targetA <- lambdaA * targetA;
	targetB <- lambdaB * targetB;

	# account for lag 
	if (lagX == 0){	
		X <- X[,c(2:dim(Y)[2], 1),];
	}
	
	# merge Y and X into an array named Z
	Z <- abind(Y, X, along=1);

	# estimation without support information neither on A nor on P
	if (nrow(zerosA) == 0 && nrow(zerosB) == 0 && nrow(zerosP) == 0){
		VARX1hat <- .armaVARX1_ridgeML(Z, 
					       lambdaA, 
					       lambdaB, 
					       lambdaP, 
					       targetA, 
					       targetB, 
					       targetP, 
					       targetPtype, 
					       fitAB, 
					       unbalanced, 
					       diagP, 
					       efficient, 
					       nInit, 
					       minSuccDiff);
 		Phat <- VARX1hat$P; 
		Ahat <- VARX1hat$A; 
		Bhat <- VARX1hat$B;
	}

	# estimation with support information on A but not on P
	if ((nrow(zerosA) > 0 | nrow(zerosB) > 0) && nrow(zerosP) == 0){
		# zerosB[,2] <- zerosB[,2] + dim(Y)[1]
		VARX1hat <- .armaVARX1_ridgeML_zerosC(Z, 
		                                      lambdaA, 
		                                      lambdaB, 
		                                      lambdaP, 
		                                      targetA, 
		                                      targetB, 
		                                      targetP, 
		                                      targetPtype, 
		                                      fitAB,
		                                      unbalanced, 
		                                      diagP, 
		                                      efficient, 
		                                      nInit, 
		                                      minSuccDiff, 
		                                      zerosA[,1], 
		                                      zerosA[,2], 
		                                      zerosB[,1], 
		                                      zerosB[,2], 
		                                      zerosAfit, 
		                                      zerosBfit);
 		Phat <- VARX1hat$P; 
		Ahat <- VARX1hat$A; 
		Bhat <- VARX1hat$B;
	}

	# estimation with support information both on A and on P
	if (nrow(zerosP) > 0){
		if (fitAB == "ss"){
			# set profiles of missing (time, sample)-points to missing
			if (!is.null(unbalanced)){ 
				Y <- .armaVAR_array2cube_withMissing(Y, 
				                                     unbalanced[,1], 
				                                     unbalanced[,2]); 
			}
			if (!is.null(unbalanced)){ 
				X <- .armaVAR_array2cube_withMissing(X, 
								     unbalanced[,1], 
								     unbalanced[,2]); 
			}

			# estimate A by SS minimization
			VARZ <- .armaVAR1_VARYhat(Z, efficient, unbalanced);
			COVZ <- .armaVARX1_COVZhat(Z, dim(Y)[1]);
                
			# estimate A
			if (nrow(zerosA) == 0 && nrow(zerosB) == 0){
				Chat <- .armaVARX1_Chat_ridgeSS(COVZ, 
				                                VARZ, 
				                                lambdaA, 
				                                lambdaB, 
				                                targetA, 
				                                targetB);
			} else {
				# eigen-decomposition of VARY
				VARZ <- .armaEigenDecomp(VARZ);
				Chat <- .armaVARX1_Chat_zeros(diag(ncol(targetA)), 
				                              COVZ, 
				                              VARZ$vectors, 
				                              VARZ$values, 
				                              lambdaA, 
				                              lambdaB, 
				                              targetA, 
				                              targetB, 
				                              fitAB, 
				                              zerosA[,1], 
				                              zerosA[,2], 
				                              zerosB[,1], 
				                              zerosB[,2], 
				                              zerosAfit, 
				                              zerosBfit);
			}

			# calculate Se
			Se <- .armaVARX1_Shat_ML(Z, 
			                         Chat[,1:dim(targetA)[1]], 
			                         Chat[,-c(1:dim(targetA)[1])]);
	
			# if cliques and separators of support of P are not provided:
			if (length(cliquesP)==0){
				supportPinfo <- support4ridgeP(zeros=zerosP, nNodes=dim(Y)[1]);
				cliquesP     <- supportPinfo$cliques; 
				separatorsP  <- supportPinfo$separators; 
				zerosP       <- supportPinfo$zeros;
			}
	
			# ridge ML estimation of Se
			if (is.character(targetP)){ 
				target <- .armaP_defaultTarget(Se, 
				                               targetType=targetPtype, 
				                               fraction=0.0001, 
				                               multiplier=0) 
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
			                      verbose=FALSE)
		}
		if (fitAB == "ml"){
			# set profiles of missing (time, sample)-points to missing
			if (!is.null(unbalanced)){ 
				Y <- .armaVAR_array2cube_withMissing(Y, 
				                                     unbalanced[,1], 
				                                     unbalanced[,2]); 
			}
			if (!is.null(unbalanced)){ 
				X <- .armaVAR_array2cube_withMissing(X, 
				                                     unbalanced[,1], 
				                                     unbalanced[,2]); 
			}

			# estimate A by SS minimization
			VARZ <- .armaVAR1_VARYhat(Z, efficient, unbalanced);
			COVZ <- .armaVARX1_COVZhat(Z, dim(Y)[1]);
			Chat <- .armaVARX1_Chat_ridgeSS(COVZ, 
			                                VARZ, 
			                                lambdaA, 
			                                lambdaB, 
			                                targetA, 
			                                targetB);

			# calculate Se
			Se <- .armaVARX1_Shat_ML(Z, 
			                         Chat[,1:dim(targetA)[1]], 
			                         Chat[,-c(1:dim(targetA)[1])]);	
            
			# if cliques and separators of support of P are not provided:
			if (length(cliquesP)==0){
				supportPinfo <- support4ridgeP(zeros=zerosP, nNodes=dim(Y)[1]);
				cliquesP     <- supportPinfo$cliques; 
				separatorsP  <- supportPinfo$separators; 
				zerosP       <- supportPinfo$zeros;
			}
	
			# ridge ML estimation of Se
			if (is.character(targetP)){ 
				target <- .armaP_defaultTarget(Se, 
				                               targetType=targetPtype, 
				                               fraction=0.0001, 
				                               multiplier=0) 
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
			                      verbose=FALSE)

			###############################################################################
			# estimate parameters by ML, using the SS estimates as initials
			###############################################################################
        	    
			# eigen-decomposition of VARY               
			VARZ <- .armaEigenDecomp(VARZ)
	
			for (u in 1:nInit){
				# store latest estimates
				Cprev <- Chat; 
				Pprev <- Phat;

				# estimate A
				if (nrow(zerosA) == 0 && nrow(zerosB) == 0){
					Chat <- .armaVARX1_Chat_ridgeML(Phat, 
					                                COVZ, 
					                                VARZ$vectors, 
					                                VARZ$values, 
					                                lambdaA, 
					                                lambdaB, 
					                                targetA, 
					                                targetB)
				} else {
					Chat <- .armaVARX1_Chat_zeros(Phat, 
					                              COVZ, 
					                              VARZ$vectors, 
					                              VARZ$values, 
					                              lambdaA, 
					                              lambdaB, 
					                              targetA, 
					                              targetB, 
					                              fitAB, 
					                              zerosA[,1], 
					                              zerosA[,2], 
					                              zerosB[,1], 
					                              zerosB[,2], 
					                              zerosAfit, 
					                              zerosBfit)
				}

				# calculate Se
				Se <- .armaVARX1_Shat_ML(Z, 
			                                Chat[,1:dim(targetA)[1]], 
			                                Chat[,-c(1:dim(targetA)[1])]);
                
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
				                      verbose=FALSE)
		
				# assess convergence
				if (.armaVARX1_convergenceEvaluation(Chat, Cprev, Phat, Pprev) < minSuccDiff){ 
					break 
				}
			}
		}
	        Ahat <- Chat[,1:dim(Y)[1]]; 
		Bhat <- Chat[,-c(1:dim(Y)[1])];    	
	}
	return(list(A=Ahat, 
		    B=Bhat, 
		    P=Phat, 
		    lambdaA=lambdaA, 
		    lambdaB=lambdaB, 
		    lambdaP=lambdaP))
}

