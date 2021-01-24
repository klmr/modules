source_file = function (path, language) {
    if (missing(language) || is.null(language))
        language = regmatches(path, regexpr('[^.]*$', path))
    code = paste(readLines(path), collapse = '\n')
    sprintf('```%s\n%s\n```', language, code)
}

knitr::knit_hooks$set(file = function (before, options, envir) {
    if (! before) {
        # Necessary because this file is built both as vignette and
        # independent, and this happens from different working directories.
        path_prefix = if (grepl('vignettes$', getwd())) '.' else 'vignettes'
        source_file(file.path(path_prefix, options$file), options$lang)
    }
})
