![Logo](../../blob/images/r-modules.png?raw=true) Modules for R
===============================================================

> ## 🚧 This package is deprecated! 🚧
>
> **This package is deprecated and has been replaced by [the package ‘box’](/klmr/box)**.
> ‘modules’ v0.9.x is in maintenance mode, and no new features will be
> implemented. ‘box’ is, for all intents and purposes, the spiritual successor:
> ‘modules’ v1.0.

[![Travis CI
status](https://travis-ci.org/klmr/modules.svg?branch=master)](https://travis-ci.org/klmr/modules)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/klmr/modules?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Table of contents
-----------------

* [Summary](#summary)
* [Installation](#installation)
* [Usage basics](#usage-basics)
* [Vignette][vignette]
* [Feature comparison][wiki:feature-comparison]
* [Design rationale][wiki:design]

[vignette]: ../master/doc/basic-usage.md
[wiki:feature-comparison]: ../../wiki/Feature-comparison
[wiki:design]: ../../wiki/Design-rationale


Summary
-------

This package provides an alternative mechanism of organising reusable code into
units, called “modules”. Its usage and organisation is reminiscent of Python’s.
It is designed so that normal R source files are automatically modules, and need
not be augmented by meta information or wrapped in order to be distributed, in
contrast to R packages.

Modules are loaded via the syntax

```r
module = import('module')
```

Where `module` is the name of a module. Like in Python, modules can be grouped
together in submodules, so that a name of a module could be, e.g.
`tools/strings`. This could be used via

```r
str = import('tools/strings')
```

This will import the code from a file with the name `tools/strings.r`, located
either under the local directory or at a predefined, configurable location.

Exported functions of the module could then be accessed via `str$func`:

```r
some_string = 'Hello, World!'
upper = str$to_upper(some_string)
# => 'HELLO, WORLD!'
```

Notice that we’ve aliased the actual module name to `str` in user code.

Alternatively, modules can be imported into the global namespace:

```r
import('tools/strings', attach = TRUE)
```

The module is then added to R’s `search()` vector (or equivalent) so that
functions can be accessed without qualifying the module’s imported name each
time.

R modules are normal R source files. However, `import` is different from
`source` in some crucial regards. It’s also crucially different from normal
packages. Please refer to the [comparison][wiki:feature-comparison] for details.


### But I need packages!

Not to worry, simply use `import_package` instead of `import` and treat the
imported package the same way you would treat a module:

```r
dplyr = import_package('dplyr')
cars %>% dplyr$filter(speed > 15)
```

For consistency, `library` and `require` should not be used in conjunction with
modules (although they can).

Installation
------------

To install using [*devtools*](https://github.com/hadley/devtools), just type the
following command in R:

```r
devtools::install_github('klmr/modules')
```

[Wiki: Installation][wiki:install] has more information.

[wiki:install]: ../../wiki/Installation

Usage basics
------------

Local, single-file modules can be used as-is: assuming you have a file called
`foo.r` in your current directory, execute

```r
foo = import('foo')
# or: foo = import('./foo')
```

in R to make its content accessible via a module, and use it via
`foo$function_name(…)`. Alternatively, you can use

```r
import('foo', attach = TRUE)
```

But this form is usually discouraged (at the file scope) since it clutters the
global search path (although it’s worth noting that modules are isolated
namespaced and don’t leak their scope).

If you want to access a module in a non-local path, the cleanest way is to
create a central repository (e.g. at `~/.R/modules`) and to copy module source
files there. Now `import` needs to know how to find this repository. This can be
done by either setting the environment variable `R_IMPORT_PATH` or, inside R
(e.g. in `~/.Rprofile`), via `options('import.path')`.

Nested modules (called “packages” in Python, but for obvious reasons this name
is not used for R modules) are directories (either local, or in the import
search path) which optionally contain an `__init__.r` file. Assuming you have
such a module `foo`, inside which is a submodule `bar`, you can then make it
available in R via

```r
foo = import('foo')     # Make available foo, or
bar = import('foo/bar') # Make available only foo/bar
```

During module development, you can `reload` a module to reflect its changes
inside R, or `unload` it. In order to do this, you need to have assigned the
result of `import` to an identifier.
