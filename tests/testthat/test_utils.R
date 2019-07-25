library(makeParallel)


test_that("descendant removal", {

    nodes = list(c(1, 2), c(1, 2, 4))

    actual = hasAncestors(nodes)

    expect_equal(c(FALSE, TRUE), actual)

})


test_that("find_var", {

    expr = quote(x[1:5])

    expect_equal(find_var(expr, "x"), list(2))

    expr = quote(y[1:5])
    expect_equal(find_var(expr, "x"), list())

    expr = quote(mean(x[1:5]))
    expect_equal(find_var(expr, "x"), list(c(2, 2)))

    expr = quote(plot(dframe[, "d"]))
    actual = find_var(expr, "dframe")

    expect_equal(actual, list(c(2, 2)))

    expr = quote(mean(x[1:5]) + x)
    actual = find_var(expr, "x")
    # I don't care about the order of the elements of this list.
    expect_equal(actual, list(c(2, 2, 2), 3))

    # Don't match character vectors
    expr = quote(paste("x", "y"))
    expect_equal(find_var(expr, "y"), list())

    expr = parse(text = '
        d = read.csv("data.csv")
        hist(d[, 2])
    ')
    actual = find_var(expr, "read.csv")

    expect_equal(actual, list(c(1, 3, 1)))


    expr = parse(text = '
        f = function(end, start = x) area(sin, start, end)
        f(x)
    ')

    # expr[[c(1, 3, 2, 2)]] = as.symbol("z")
    # TODO: Running the above results in `expr` still printing `x`, but
    # code evaluates as if it were changed to `z`.
    # I don't know what's happening.

    actual = find_var(expr, "x")

    expect_equal(actual, list(c(1, 3, 2, 2), c(2, 2)))

})


test_that("find_call", {

    e0 = quote(sapply(x, f))
    expect_equal(find_call(e0, "lapply"), list())

    e1 = quote(lapply(x, f))
    expect_equal(find_call(e1, "lapply"), list(1L))

    e2 = quote(y <- lapply(x, f))
    expect_equal(find_call(e2, "lapply"), list(c(3L, 1L)))

    e3 = quote(y <- c(lapply(x, f1), lapply(x, f2)))
    expect_equal(find_call(e3, "lapply"), list(c(3L, 2L, 1L), c(3L, 3L, 1L)))

    e4 = quote(y <- lapply(lapply(x, f), g))
    expect_equal(find_call(e4, "lapply"), list(c(3L, 1L), c(3L, 2L, 1L)))

})


test_that("tree methods", {

    tree = list(list(list(1, 2, 3), 4), 5)
    actual = tree[[c(1, 1, 2)]]
    expect_equal(actual, 2)

})


test_that("symbol replacement", {

    e = parse(text = "
        bar = FOO
        BAZ
        ", keep.source = FALSE)

    actual = substitute_language(e, list(FOO = quote(foo_new), BAZ = quote(f(g(foo_new)))))

    expected = parse(text = "
        bar = foo_new
        f(g(foo_new))
        ", keep.source = FALSE)

    expect_equal(actual, expected)

    e2 = parse(text = "
        `_BODY`
        foo(bar)
        ")

    actual = substitute_language(e2, list(`_BODY` = e))

    expected = parse(text = "
        bar = FOO
        BAZ
        foo(bar)
        ")

    expect_equal(actual, expected)

})
