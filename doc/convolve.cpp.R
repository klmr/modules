`.sourceCpp_1_DLLInfo` <- dyn.load('/Users/konrad/source/klmr/modules/vignettes/rcpp/convolve.so')

convolve <- Rcpp:::sourceCppFunction(function(a, b) {}, FALSE, `.sourceCpp_1_DLLInfo`, 'sourceCpp_1_convolve')

rm(`.sourceCpp_1_DLLInfo`)
