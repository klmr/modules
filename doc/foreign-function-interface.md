Foreign function interface
==========================

Modules don’t have a built-in foreign function interface yet but it is
possible to integrate C++ code via the excellent
[Rcpp](http://cran.r-project.org/web/packages/Rcpp/index.html) package.

Ad-hoc compilation
------------------

As an example, take a look at the `rcpp` module found under `inst/doc`;
the module consists of a C++ source file which is loaded inside the
`__init__.r` file:

``` r
Rcpp::sourceCpp(module_file('convolve.cpp'), env = environment())
```

Here’s the C++ code itself (the example is taken from the Rcpp
documentation):

``` cpp
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
```

This module can be used like any normal module:

``` r
rcpp = import('rcpp')
ls(rcpp)
```

    ## [1] "convolve"

``` r
rcpp$convolve(1 : 3, 1 : 5)
```

    ## [1]  1  4 10 16 22 22 15

Ahead-of-time compilation
-------------------------

Unfortunately, this has a rather glaring flaw: the code is recompiled
for each new R session. In order to avoid this, we need to compile the
code *once* and save the resulting dynamic library. There’s no
straightforward way of doing this, but Rcpp wraps `R CMD SHLIB`.

For the time being, we manually need to trigger compilation by executing
the [`__install__.r`](rcpp/__install__.r) file found in the
`inst/doc/rcpp` module path.

Once that’s done, the actual module code is easy enough:

``` r
# Load compiled module meta information, and load R wrapper code, which, in
# turn, loads the compiled module via `dyn.load`.
load_dynamic = function (prefix) {
    context = readRDS(module_file(sprintf('%s.rds', prefix)))
    source(context$rSourceFilename, local = parent.frame())
}

load_dynamic('convolve')
```

We can use it like any other module:

``` r
compiled = import('rcpp/compiled')
compiled$convolve(1 : 3, 1 : 5)
```

    ## [1]  1  4 10 16 22 22 15
