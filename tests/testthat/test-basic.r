context('Basic import test')

test_that('module can be imported', {
    a = import('a')
    expect_true(is_module_loaded(module_path(a)))
    expect_true('double' %in% ls(a))
})

test_that('import works in global namespace', {
    local({
        # Necessary since private names are not exported to global environment
        # when invoked via `testthat::test_check`.
        mod_ns = getNamespace('modules')
        a = import('a')
        on.exit(unload(a)) # To get rid of attached operators.
        expect_true(mod_ns$is_module_loaded(mod_ns$module_path(a)))
        expect_true('double' %in% ls(a))
    }, envir = .GlobalEnv)
})

test_that('module is uniquely identified by path', {
    a = import('a')
    ba = import('b/a')
    expect_true(is_module_loaded(module_path(a)))
    expect_true(is_module_loaded(module_path(ba)))
    expect_not_identical(module_path(a), module_path(ba))
    expect_true('double' %in% ls(a))
    expect_false('double' %in% ls(ba))
})

test_that('can use imported function', {
    a = import('a')
    expect_that(a$double(42), equals(42 * 2))
})

test_that('modules export all objects', {
    a = import('a')
    expect_gt(length(lsf.str(a)), 0)
    expect_gt(length(ls(a)), length(lsf.str(a)))
    a_namespace = environment(a$double)
    expect_that(a$counter, equals(1))
})

test_that('module can modify its variables', {
    a = import('a')
    counter = a$get_counter()
    a$inc()
    expect_that(a$get_counter(), equals(counter + 1))
})

test_that('hidden objects are not exported', {
    a = import('a')
    expect_true(exists('counter', envir = a))
    expect_false(exists('.modname', envir = a))
})

test_that('module bindings are locked', {
    a = import('a')

    expect_true(environmentIsLocked(a))
    expect_true(bindingIsLocked('get_counter', a))
    expect_true(bindingIsLocked('counter', a))

    err = try({a$counter = 2}, silent = TRUE)
    expect_that(class(err), equals('try-error'))
})

test_that('global scope is not leaking into modules', {
    local({
        on.exit(rm(x))
        x = 1L
        expect_error(import('issue151'), 'object .* not found')

        expect_error(import('issue151_a'), NA)
    }, envir = .GlobalEnv)
})
