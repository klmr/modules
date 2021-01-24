Basic module usage
==================

The `seq` module
----------------

For the purpose of this tutorial, we are going to use the toy module
`utils/seq`, which is implemented in the file
[`utils/seq.r`](utils/seq.r). The module implements some very basic
mechanisms to deal with DNA sequences (character strings consisting
entirely of the letters `A`, `C`, `G` and `T`).

First, we load the module.

``` r
seq = import('utils/seq')
ls()
```

    ## [1] "seq"

`utils` serves as a supermodule here, which groups several submodules
(but for now, `seq` is the only one).

To see which functions a module exports, use `ls`:

``` r
ls(seq)
```

    ## [1] "print.seq"         "revcomp"           "seq"              
    ## [4] "table"             "valid_seq"         "valid_seq.default"
    ## [7] "valid_seq.seq"

And we can display interactive help for individual functions:

``` r
?seq$seq
```

This function creates a biological sequence. We can use it:

``` r
s = seq$seq(c(foo = 'GATTACAGATCAGCTCAGCACCTAGCACTATCAGCAAC',
              bar = 'CATAGCAACTGACATCACAGCG'))
s
```

    ## >foo
    ## GATTACAGATCAGCTCAGCACCTAGCACTATCAGCAAC
    ## >bar
    ## CATAGCAACTGACATCACAGCG

Notice how we get a pretty-printed,
[FASTA](http://en.wikipedia.org/wiki/FASTA_format)-like output because
the `print` method is redefined for the `seq` class in `utils/seq`:

``` r
seq$print.seq
```

    ## function (seq, columns = 60) 
    ## {
    ##     lines = strsplit(seq, sprintf("(?<=.{%s})", columns), perl = TRUE)
    ##     print_single = function(seq, name) {
    ##         if (!is.null(name)) 
    ##             cat(sprintf(">%s\n", name))
    ##         cat(seq, sep = "\n")
    ##     }
    ##     names = if (is.null(names(seq))) 
    ##         list(NULL)
    ##     else names(seq)
    ##     Map(print_single, lines, names)
    ##     invisible(seq)
    ## }
    ## <environment: 0x7ff018b01988>

Attaching modules
-----------------

That’s it for basic usage. In order to understand more about the module
mechanism, let’s look at an alternative usage:

``` r
# We can unload loaded modules that we assigned to an identifier:
unload(seq)

options(import.path = 'utils')
import('seq', attach = TRUE)
```

After unloading the already loaded module, the `options` function call
sets the module search path: this is where `import` searches for
modules. If more than one path is given, `import` searches them all
until a module of matching name is found.

The `import` statement can now simply specify `seq` instead of
`utils/seq` as the module name. We also specify `attach=TRUE`. This has
an effect similar to package loading (or `attach`ing an environment):
all the module’s names are now available for direct use without
necessitating the `seq$` qualifier.

However, unlike the `attach` function, module attachment happens *in
local scope* only. Since the above code was executed in global scope,
there’s no distinction between local and global scope:

``` r
search()
```

    ##  [1] ".GlobalEnv"        "module:seq"        "devtools_shims"   
    ##  [4] "package:modules"   "package:testthat"  "package:stats"    
    ##  [7] "package:graphics"  "package:grDevices" "package:utils"    
    ## [10] "package:datasets"  "rprofile"          "package:methods"  
    ## [13] "Autoloads"         "package:base"

Notice the second position, which reads “module:seq”. But now let’s undo
that, and attach (and use) the module locally instead.

``` r
detach('module:seq') # Name is optional
local({
    import('seq', attach = TRUE)
    table('GATTACA')
})
```

    ## [[1]]
    ## 
    ## A C G T 
    ## 3 1 1 2

Note that this uses `seq`’s `table` function, rather than `base::table`
(which would have a different output). Furthermore, note that *outside*
the local scope, the module is not attached:

``` r
search()
```

    ##  [1] ".GlobalEnv"        "devtools_shims"    "package:modules"  
    ##  [4] "package:testthat"  "package:stats"     "package:graphics" 
    ##  [7] "package:grDevices" "package:utils"     "package:datasets" 
    ## [10] "rprofile"          "package:methods"   "Autoloads"        
    ## [13] "package:base"

``` r
table('GATTACA')
```

    ## 
    ## GATTACA 
    ##       1

This is very powerful, as it isolates separate scopes more effectively
than the `attach` function. What is more, modules which are imported and
attached inside another module *remain* inside that module and are not
visible outside the module by default.

Nevertheless, the normal, recommended usage of a module is with
`attach=FALSE` (the default), as this makes it clearer which names we
are referring to.

Nested modules
--------------

Modules can also be nested in hierarchies. In fact, here is the
implementation of `utils` (in [`utils/__init__.r`](utils/__init__.r):
since `utils` is a directory rather than a file, the module
implementation resides in the nested file `__init__.r`):

``` r
seq = import('./seq')
```

The submodule is specified as `'./seq'` rather than `'seq'`: the
explicitly provided relative path prevents lookup in the import search
path (that we set via `options(import.path=…)` earlier); instead, only
the current directory is considered.

We can now use the `utils` module:

``` r
options(import.path = NULL) # Reset search path
utils = import('utils')
ls(utils)
```

    ## [1] "seq"

``` r
ls(utils$seq)
```

    ## [1] "print.seq"         "revcomp"           "seq"              
    ## [4] "table"             "valid_seq"         "valid_seq.default"
    ## [7] "valid_seq.seq"

``` r
utils$seq$revcomp('CAT')
```

    ## ATG

We could also have implemented `utils` as follows:

``` r
export_submodule('./seq')
```

This would have made all of `seq`’s definitions immediately available in
`utils`. This is sometimes useful, but should be employed with care.

Implementing modules
--------------------

`utils/seq.r` is, by and large, a normal R source file. In fact, there
are only two things worth mentioning:

1.  Documentation. Each function in the module file is documented using
    the
    [roxygen2](http://cran.r-project.org/web/packages/roxygen2/index.html)
    syntax. It works the same as for packages. The *modules* package
    parses the documentation and makes it available via `module_help`
    and `?`.

2.  The module exports [S3 functions](http://adv-r.had.co.nz/S3.html).
    The *modules* package takes care to register such functions
    automatically but this only works for *user generics* that are
    defined inside the same module. When overriding “known generics”
    (such as `print`), we need to register these manually via
    `register_S3_method` (this is necessary since these functions are
    inherently ambiguous and there is no automatic way of finding them).

Module files can contain arbitrary code. It is executed when loaded for
the first time: subsequent `import`s in the same session, regardless of
whether they occur in a different scope, will refer to the loaded,
cached module, and will *not* reload a module.

We can illustrate this by loading a module which has side-effects,
`'info'`.

``` r
message('Loading module "', module_name(), '"')
message('Module path: "', basename(module_file()), '"')
```

Let’s load it:

``` r
info = import('info')
```

    ## Loading module "info"

    ## Module path: "vignettes"

We have imported the module, and get the diagnostic messages. Let’s
re-import the module:

``` r
import('info')
```

… no messages are displayed. However, we can explicitly *reload* a
module. This clears the cache, and loads the module again:

``` r
reload(info)
```

    ## Loading module "info"

    ## Module path: "vignettes"

And this displays the messages again. The `reload` function is a
shortcut for `unload` followed by `import` (using the exact same
arguments as used on the original `import` call).

The `info` module also show-cases two important helper functions:

1.  `module_name` contains the name of the module with which it was
    loaded. This is especially handy because outside of a module
    `module_name` is `NULL`. We can harness this in a similar way to
    Python’s `__name__` mechanism.

2.  `module_file` works equivalently to `system.file`: it returns the
    full path to any file within a module. This is helpful when
    distributing data files with modules, which are loaded from within
    the module. When invoked without arguments, `module_file` returns
    the full path to the directory containing the module source file.
