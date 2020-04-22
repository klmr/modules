context('Test that modules works with knitr')

check_knitr = function () skip_if_not_installed('knitr')

safe_unload_namespace = function (ns) {
    users = getNamespaceUsers(ns)
    for (user in users) safe_unload_namespace(user)
    unloadNamespace(ns)
}

test_that('modules are found when knitr is not loaded', {
    check_knitr()
    # Ensure knitr isn’t loaded
    safe_unload_namespace('knitr')
    expect_paths_equal(script_path(), getwd())
})

test_that('modules are found when knitr is loaded', {
    check_knitr()
    loadNamespace('knitr')
    on.exit(safe_unload_namespace('knitr'))
    expect_paths_equal(script_path(), getwd())
})

test_that('modules are found inside a knitr document', {
    check_knitr()
    on.exit(safe_unload_namespace('knitr'))

    input = 'support/knitr/doc.rmd'
    # Ensure that a different working directory is used.
    knitr::opts_knit$set(root.dir = getwd())
    output = knitr::knit(input, quiet = TRUE)
    on.exit(unlink(output), add = TRUE)

    expected = '```\n## knitr/a\n```'
    expect_match(paste(readLines(output), collapse = '\n'), expected)
})
