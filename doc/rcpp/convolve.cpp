#include "Rcpp.h"

using Rcpp::NumericVector;

// [[Rcpp::export]]
NumericVector convolve(NumericVector a, NumericVector b) {
    int na = a.size(), nb = b.size();
    int nab = na + nb - 1;
    NumericVector xab(nab);
    for (int i = 0; i < na; i++)
        for (int j = 0; j < nb; j++)
            xab[i + j] += a[i] * b[j];
    return xab;
}
