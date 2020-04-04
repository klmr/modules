#' Import a module into the current scope
#'
#' \code{module = import('module')} imports a specified module and makes its
#' code available via the environment-like object it returns.
#'
#' @param module a character string specifying the full module path
#' @param attach either a boolean or a  character vector. If \code{TRUE}, attach
#'  the newly loaded module to the object search path (see \code{Details}).
#'  Alternatively, if a character vector is given, attach only the listed names.
#' @param attach_operators if \code{TRUE}, attach operators of module to the
#'  object search path, even if \code{attach} is \code{FALSE}
#' @param doc boolean specifying whether to load the module’s documentation (see
#'  \code{Details})
#' @return the loaded module environment (invisible)
#'
#' @details Modules are loaded in an isolated environment which is returned, and
#' optionally attached to the object search path of the current scope (if
#' argument \code{attach} is \code{TRUE}).
#' \code{attach} defaults to \code{FALSE}. However, in interactive code it is
#' often helpful to attach packages by default. Therefore, in interactive code
#' invoked directly from the terminal only (i.e. not within modules),
#' \code{attach} defaults to the value of \code{options('import.attach')}, which
#' can be set to \code{TRUE} or \code{FALSE} depending on the user’s preference.
#'
#' \code{attach_operators} causes \emph{operators} to be attached by default,
#' because operators can only be invoked in R if they re found in the search
#' path. Not attaching them therefore drastically limits a module’s usefulness.
#'
#' \code{doc} loads the module’s documentation, specified as roxygen comments.
#' It defaults to \code{TRUE} in interactive mode and to \code{FALSE} otherwise.
#'
#' Modules are searched in the module search path \code{options('import.path')}.
#' This is a vector of paths to consider, from the highest to the lowest
#' priority. The current directory is \emph{always} considered last. That is,
#' if a file \code{a.r} exists both in the current directory and in a module
#' search path, the local file \code{./a.r} will not be loaded, unless the
#' import is explicitly specified as \code{import('./a')}.
#'
#' Module names can be fully qualified to refer to nested paths. See
#' \code{Examples}.
#'
#' Module source code files are assumed to be encoded in UTF-8 without BOM.
#' Ensure that this is the case when using an extended character set.
#'
#' @note Unlike for \code{\link{library}}, attaching happens \emph{locally}: if
#' \code{import} is executed in the global environment, the effect is the same.
#' Otherwise, the imported module is inserted as the parent of the current
#' \code{environment()}. When used (globally) \emph{inside} a module, the newly
#' imported module is only available inside the module’s search path, not
#' outside it (nor in other modules which might be loaded).
#'
#' @examples
#' \dontrun{
#' # `a.r` is a file in the local directory containing a function `f`.
#' a = import('a')
#' a$f()
#'
#' # b/c.r is a file in path `b`, containing functions `f` and `g`.
#' import('b/c', attach = 'f')
#' # No module name qualification necessary
#' f()
#' g() # Error: could not find function "g"
#'
#' import('b/c', attach = TRUE)
#' f()
#' g()
#' }
#' @seealso \code{\link{unload}}
#' @seealso \code{\link{reload}}
#' @seealso \code{\link{module_name}}
#' @seealso \code{\link{module_help}}
#' @export
#' @rdname import
import_ = function (module, attach, attach_operators = TRUE, doc) {
    stopifnot(inherits(module, 'character'))

    if (missing(attach)) {
        attach = if (interactive() && is.null(module_name()))
            getOption('import.attach', FALSE)
        else
            FALSE
    }

    stopifnot(class(attach) == 'logical' && length(attach) == 1 ||
              class(attach) == 'character')

    if (is.character(attach)) {
        export_list = attach
        attach = TRUE
    }
    else
        export_list = NULL

    if (missing(doc))
        doc = interactive()

    module_path = try(find_module(module), silent = TRUE)

    if (inherits(module_path, 'try-error'))
        stop(attr(module_path, 'condition')$message)

    containing_modules = module_init_files(module, module_path)
    mapply(do_import, names(containing_modules), containing_modules,
           rep(doc, length(containing_modules)))

    mod_ns = do_import(module, module_path, doc)
    module_parent = parent.frame()
    mod_env = exhibit_module_namespace(mod_ns, module, module_parent,
                                       export_list)

    attach_module(attach, attach_operators, module, mod_env, module_parent)

    attr(mod_env, 'call') = match.call()
    lockEnvironment(mod_env, bindings = TRUE)
    invisible(mod_env)
}

#' @export
#' @rdname import
import = function (module, attach, attach_operators = TRUE, doc) {
    # Substitute exactly `import` with `import_` in call. This ensures that the
    # call works regardless of whether it was bare or qualified
    # (`modules::import`).
    call = sys.call()
    call[[1]] = do.call(substitute,
                        list(call[[1]], list(import = quote(import_))))
    if (! inherits(substitute(module), 'character')) {
        msg = sprintf(paste('Calling %s with a variable will change its',
                            'semantics in version 1.0 of %s. Use %s instead.',
                            'See %s for more information.'),
                      sQuote('import'), sQuote('modules'),
                      sQuote(deparse(call)),
                      sQuote('https://github.com/klmr/modules/issues/68'))
        .Deprecated(msg = msg)
    }
    eval.parent(call)
}

#' Attach a module environment locally or globally
#'
#' @param all logical specifying whether to attach the whole module
#' @param operators logical specifying whether to attach operators
#' @param name the module name
#' @param mod_env the module environment to attach
#' @param parent the module parent environment
#' @details
#' If neither \code{all} nor \code{operators} are \code{TRUE}, this function
#' does nothing. Otherwise, it will either attach the whole module environment
#' or the operators it exports. Attaching is done by inserting the module at the
#' first position into the parent environment chain.
attach_module = function (all, operators, name, mod_env, parent) {
    attached_module = if (all)
        mod_env
    else if (operators)
        export_operators(mod_env, parent, name)
    else
        NULL

    if (is.null(attached_module))
        return()

    fix_module_attributes(parent)

    # The following distinction is necessary because R segfaults if we try
    # to change `parent.env(.GlobalEnv)`. More info:
    # http://stackoverflow.com/q/22790484/1968
    if (identical(parent, .GlobalEnv)) {
        warn = interactive() && getOption('import.warn_conflicts', TRUE)
        # To avoid spurious `R CMD CHECK` warning. Modules only uses `attach`
        # when explicitly prompted by the user, so the use should be acceptable.
        get('attach', .BaseNamespaceEnv, mode = 'function'
            )(attached_module, name = environmentName(attached_module),
            warn.conflicts = warn)
        attr(mod_env, 'attached') = environmentName(attached_module)
    }
    else
        parent.env(parent) = attached_module
}

#' Save a module’s inherited attributes into a local environment
#'
#' @param envir the environment into which to copy the inherited attributes
#' @details
#' Attaching a module to an environment makes the environment “forget” its
#' actual enclosing environment. This is important since that module holds
#' information such as the module name or path, which may be required in the
#' current local scope. To fix this, \code{fix_module_attributes} copies the
#' enclosing module’s attributes into the local environment.
fix_module_attributes = function (envir) {
    old_attributes = try(module_attributes(envir), silent = TRUE)
    if (! inherits(old_attributes, 'try-error'))
        module_attributes(envir) = old_attributes
    else
        module_attributes(envir) = new.env(parent = emptyenv())
}

#' Perform the actual import operation on an individual module
#'
#' @param module_name the name of the module, as specified by the user
#' @param module_path the fully resolved path to the module file
#' @param doc logical, whether the module documentation should be parsed
do_import = function (module_name, module_path, doc) {
    if (is_module_loaded(module_path))
        return(get_loaded_module(module_path))

    # Environment with helper functions which are only available when loading a
    # module via `import`, and are not otherwise exported by the package.

    modules_exports = sapply(getNamespaceExports(getNamespace('modules')),
                             getExportedValue,
                             ns = getNamespace('modules'),
                             simplify = FALSE)
    helper_env = list2env(c(modules_exports,
                            list(export_submodule = export_submodule,
                                 export_submodule_ = export_submodule_)),
                          parent = as.environment(2L))

    # The namespace contains a module’s content. This schema is very much like
    # R package organisation.
    # A good resource for this is:
    # <http://obeautifulcode.com/R/How-R-Searches-And-Finds-Stuff/>
    namespace = structure(new.env(parent = helper_env),
                          name = paste('namespace', module_name, sep = ':'),
                          class = c('namespace', 'environment'))

    # Necessary as of R 3.6.0; works around #147.
    namespace$.packageName = module_name

    module_attr(namespace, 'name') = environmentName(namespace)
    module_attr(namespace, 'path') = module_path

    # First cache the (still empty) namespace, then source code into it. This is
    # necessary to allow circular imports.
    cache_module(namespace)
    # If loading fails due to an error inside the module (i.e. `parse` or `eval`
    # will fail), we unload the module again.
    on.exit(uncache_module(namespace))

    # R, Windows and Unicode don’t play together. `source` does not work here.
    # See http://developer.r-project.org/Encodings_and_R.html and
    # http://stackoverflow.com/q/5031630/1968 for a discussion of this.
    eval(parse(module_path, encoding = 'UTF-8'), envir = namespace)

    make_S3_methods_known(namespace)

    if (doc)
        attr(namespace, 'doc') = parse_documentation(namespace)

    # No error occured — prevent unloading.
    on.exit()
    namespace
}

#' Copy a module’s operators into a separate environment
#'
#' This function is used to create an attachable environment containing only the
#' module’s operators, as these would otherwise not be readily usable.
#' @param environment the module environment
#' @param parent the parent environment of the calling code, to determine how to
#'  chain the environments properly
#' @param module_name the name of the module
#' @return A new environment containing the operators of the module.
#' @note This function expects the module \emph{environment} rather than the
#' \emph{namespace}. This is important because, for package modules, we only
#' want to expose exported operators, and not all exported operators are visible
#' inside the namespace (see, for example, \code{\link[dplyr]{\%>\%}}, which is
#' imported from the package “magrittr”).
export_operators = function (environment, parent, module_name) {
    ops = c('+', '-', '*', '/', '^', '**', '&', '|', ':', '::', ':::', '$',
            '$<-', '=', '<-', '<<-', '==', '<', '<=', '>', '>=', '!=', '~',
            '&&', '||', '!', '?', '@', '@<-', ':=', '(', '{', '[', '[[', '(<-',
            '{<-', '[<-')

    is_predefined = function (f) f %in% ops

    is_op = function (f) {
        # `.` delimits an S3 method name, but only when not inside `%…%`.
        prefix = regmatches(f, regexpr('^[^.]+|(%[^%]*%)', f))
        is_predefined(prefix) || grepl('^%.*%$', prefix)
    }

    operators = Filter(is_op, lsf.str(environment))

    if (length(operators) == 0)
        return()

    # Skip one parent environment because this module is hooked into the chain
    # between the calling environment and its ancestor, thus sitting in its
    # local object search path.
    exhibit_namespace(mget(operators, envir = environment),
                      paste('operators', module_name, sep = ':'),
                      module_path(environment),
                      NULL,
                      parent)
}

#' Unload a given module
#'
#' Unset the module variable that is being passed as a parameter, and remove the
#' loaded module from cache.
#' @param module reference to the module which should be unloaded
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. However, subsequently importing the module again will reload its
#' source files, which would not have happened without \code{unload}.
#' Unloading modules is primarily useful for testing during development, and
#' should not be used in production code.
#'
#' \code{unload} comes with a few restrictions. It attempts to detach itself
#' if it was previously attached. This only works if it is called in the same
#' scope as the original \code{import}.
#' @seealso \code{\link{import}}
#' @seealso \code{\link{reload}}
#' @export
unload = function (module) {
    stopifnot(inherits(module, 'module'))
    module_ref = as.character(substitute(module))
    uncache_module(module)
    attached = attr(module, 'attached')
    if (! is.null(attached) && ! is.na(match(attached, search())))
        detach(attached, character.only = TRUE)
    # Unset the module reference in its scope, i.e. the caller’s environment or
    # some parent thereof.
    rm(list = module_ref, envir = parent.frame(), inherits = TRUE)
}

#' Reload a given module
#'
#' Remove the loaded module from the cache, forcing a reload. The newly reloaded
#' module is assigned to the module reference in the calling scope.
#' @param module reference to the module which should be unloaded
#' @note Any other references to the loaded modules remain unchanged, and will
#' still work. Reloading modules is primarily useful for testing during
#' development, and should not be used in production code.
#'
#' \code{reload} comes with a few restrictions. It attempts to re-attach itself
#' in parts or whole if it was previously attached in parts or whole. This only
#' works if it is called in the same scope as the original \code{import}.
#' @seealso \code{\link{import}}
#' @seealso \code{\link{unload}}
#' @export
reload = function (module) {
    stopifnot(inherits(module, 'module'))
    module_ref = as.character(substitute(module))

    module_ns = get_loaded_module(module_path(module))
    uncache_module(module)
    # If loading fails, restore old module.
    on.exit(cache_module(module_ns))

    attached = attr(module, 'attached')
    if (! is.null(attached)) {
        attached_pos = match(attached, search())
        if (! is.na(attached_pos)) {
            attached_env = as.environment(attached)
            detach(attached, character.only = TRUE)
            # To avoid spurious `R CMD CHECK` warning. Modules only uses
            # `attach` when explicitly prompted by the user, so the use should
            # be acceptable.
            on.exit(get('attach', .BaseNamespaceEnv, mode = 'function')
                    (attached_env, pos = attached_pos, name = attached),
                    add = TRUE)
        }
    }

    # Use `eval` to replicate the exact call being made to `import`.
    mod_env = eval.parent(attr(module, 'call'))
    # Importing worked, so cancel restoring the old module.
    on.exit()

    assign(module_ref, mod_env, envir = parent.frame(), inherits = TRUE)
}

#' @export
print.module = function (x, ...) {
    cat(sprintf('<%s>\n', module_attr(x, 'name')))
    invisible(x)
}
