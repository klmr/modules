parse_documentation = function (module) {
    module_path = module_path(module)
    roclet = roxygen2::rd_roclet()

    parsed = list(
        env = module,
        blocks = roxygen2::parse_file(module_path, module)
    )
    rdfiles = roxygen2::roclet_process(
        roclet,
        blocks = parsed$blocks,
        env = parsed$env,
        base_path = dirname(module_path)
    )

    # Due to aliases, documentation entries may have more than one name.
    aliases = lapply(rdfiles, function (rd) unique(rd$get_section('alias')$value))
    names = rep(names(aliases), lengths(aliases))
    docs = setNames(rdfiles[names], unlist(aliases))
    lapply(docs, format, wrap = FALSE)
}

#' Display module documentation
#'
#' \code{module_help} displays help on a module’s objects and functions in much
#' the same way \code{\link[utils]{help}} does for package contents.
#'
#' @param topic fully-qualified name of the object or function to get help for,
#'  in the format \code{module$function}
#' @param help_type character string specifying the output format; currently,
#'  only \code{'text'} is supported
#' @note Help is only available if \code{\link{import}} loaded the help stored
#' in the module file(s). By default, this happens only in interactive sessions.
#' @rdname help
#' @export
#' @examples
#' \dontrun{
#' mod = import('mod')
#' module_help(mod$func)
#' }
module_help = function (topic, help_type = getOption('help_type', 'text')) {
    topic = substitute(topic)

    if (! is_module_help_topic(topic, parent.frame()))
        stop(sQuote(deparse(topic)), ' is not a valid module help topic',
             call. = FALSE)

    module = get(as.character(topic[[2]]), parent.frame())
    module_name = module_name(module)
    object = as.character(topic[[3]])

    doc = attr(module, 'doc')[[object]]
    if (is.null(doc))
        stop('No documentation available for ', sQuote(object),
             ' in module ', sQuote(module_name), call. = FALSE)

    display_help(doc, paste0('module:', module_name), help_type)
}

is_module_help_topic = function (topic, parent) {
    # For nested modules, `topic` looks like this: `a$b$c…`. We need to retrieve
    # the first part of this (`a`) and check whether it’s a module.

    leftmost_name = function (expr) {
        if (is.name(expr))
            expr
        else if (! is.call(expr) || expr[[1]] != '$')
            NULL
        else
            leftmost_name(expr[[2]])
    }

    top_module = leftmost_name(topic)

    ! is.null(top_module) &&
        exists(as.character(top_module), parent) &&
        ! is.null(module_name(get(as.character(top_module), parent)))
}

#' @usage
#' # ?module$function
#' @inheritParams utils::`?`
#' @rdname help
#' @export
#' @examples
#' \dontrun{
#' ?mod$func
#' }
`?` = function (e1, e2) {
    topic = substitute(e1)
    if (missing(e2) && is_module_help_topic(topic, parent.frame()))
        eval(call('module_help', topic), envir = parent.frame())
    else {
        delegate = if ('devtools_shims' %in% search())
            get('?', pos = 'devtools_shims')
        else
            utils::`?`
        eval(`[[<-`(match.call(), 1, delegate), envir = parent.frame())
    }
}

#' @usage
#' # help(module$function)
#' @inheritParams utils::help
#' @export
#' @examples
#' \dontrun{
#' help(mod$func)
#' }
help = function (topic, ...) {
    topic = substitute(topic)
    delegate = if (! missing(topic) &&
                   is_module_help_topic(topic, parent.frame())) {
        module_help
    } else if ('devtools_shims' %in% search()) {
        get('help', pos = 'devtools_shims')
    } else {
        utils::help
    }
    eval(`[[<-`(match.call(), 1, delegate), envir = parent.frame())
}
