* 0.9.12:
    * Fix: Update to new roxygen2 version 7 API (#150)

* 0.9.11:
    * Fix `script_path` when R arguments contain certain valid patterns (#148)
    * Fix S3 modules on R 3.6.0 (#147)

* 0.9.10:
    * Fix incompatibility with roxygen2 v6.1.0

* 0.9.9:
    * Fix `module_file` argument check (#90)
    * Add clickable links to “See also” section in documentation (#56)
    * Fix a regression in the “basic-usage” vignette (#122)
    * Dispatch calls to `` `?` `` and `help` to devtools, if necessary (#34)
    * Run `document` twice to ensure S3 exports are correctly generated (#117,
      hadley/devtools#1585)
    * Make Shiny runtime test more robust (#69)
    * Fix crash in S3 recognition when function bodies have been substituted at
      runtime (#125)

* 0.9.8:
    * Fix missing S3 methods bug (#117)
    * Fix missing exported operators (#93)

* 0.9.7:
    * Support rudimentary HTML help
    * Fix `help(package = …)` (#38, #73)

* 0.9.6:
    * Fix broken interaction with Roxygen2 (#103)

* 0.9.5:
    * Locally attach ‹modules› inside modules (#44)

* 0.9.4:
    * Fix regression in 0.9 when ‹modules› package is not attached
    * Fix `R CMD CHECK` warnings
    * Fix missing documentation of `import` (#78)

* 0.9.3:
    * Fix regression in 0.9 due to attachment of operator environment (#71)
    * Fix another typo in test for deprecation warning (from #68)

* 0.9.2:
    * Fix missing export of `export_submodule_` (#75)

* 0.9.1:
    * Fix typo in test for deprecation warning (from #68)
    * Disable name conflict warning when run in non-interactive mode (#48)

* 0.9:
    * Fix wrong module name and path information after a module has been
      attached (#66, #67, #70)
    * Deprecate usage of variables for package names (#68)

* 0.8.2:
    * Fix loading of a package that contains errors (#58)
    * Fix `reload` overwriting the wrong object if its name is shadowed by the
      name of the reloaded module (#51)
    * Fix loading of S3 generics without associated methods (#63)

* 0.8.1:
    * Fix bug concerning wrong operator attachment for packages

* 0.8:
    * Add support for importing packages (#45)
    * Make module access operator `$` stricter
    * Improve type checking (module access operator `$` is stricter, #55)

* 0.7.3:
    * Add Shiny support (#53, rstudio/shinyapps#152)

* 0.7.2:
    * Fix building of vignette (#52)
    * Add support for knitr with help from @yihui (#31, yihui/knitr#950)

* 0.7.1:
    * Add a vignette
    * Fix operators whose name contains a dot

* 0.7:
    * Add support for S3 methods in modules

* 0.6.1:
    * Support aliases and illegal R names for documentation topics

* 0.6:
    * Add support for documentation via roxygen2 doc comments in modules

* 0.5:
    * Assume all module source files are UTF-8 encoded
    * Export non-function objects as well as functions
    * Lock exported namespace so that its symbols cannot be modified
    * Add `export_submodule` function
    * Improve documentation

* 0.4:
    * Make imports absolute by default, and add ability for explicit relative
      imports via the `./` or `../` prefix, and use the current script path as
      the base path, rather than the current working directory, when invoking a
      script via `R CMD BATCH` or `Rscript`
    * Do not change `getwd()` when `import`ing
    * Remove requirement for `__init__.r` as supermodule markers
    * Make `unload` and `reload` aware of globally attached modules
    * Fix `module_name` bug
    * Add `module_file` function which works akin to `system.file`
    * Pretty-print module objects
    * Support circular dependencies between modules
    * Fix (hopefully) installation on Windows by specifying project encoding

* 0.3:
    * Add capability of partially attaching modules

* 0.2:
    * Change the API to use quoted strings instead of unevaluated
      expressions, and slashes instead of dots to denote nested submodules
    * Attach operators even if other functions are not attached, to make them
      usable

* 0.1: Initial release
