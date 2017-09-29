library(autoparallel)

test_that("replacing functions", {

    expr = parse(text = "
        # Testing code:
        n = 1000000L
        p = 20L
        x = matrix(1:(n*p), ncol = p)
        x
        colmaxs = apply(x, 2, max)
        colmaxs2 <- apply(x, 2, max)
        assign('colmaxs3', apply(x, 2, max))
        apply(x, 2, min)
    ")

    sub_one_docall(expr, list(apply = quote(FANCY_APPLY)))

})


test_that("findvar", {

    expr = quote(x[1:5])
    expect_equal(findvar(expr, "x"), list(2))

    expr = quote(y[1:5])
    expect_equal(findvar(expr, "x"), list())

    expr = quote(mean(x[1:5]))
    expect_equal(findvar(expr, "x"), list(c(2, 2)))

    #TODO: Problem is the missing arg.
    expr = quote(plot(dframe[, "d"]))
    actual = findvar(expr, "dframe")

    expect_equal(actual, list(c(2, 2)))

    expr = quote(mean(x[1:5]) + x)
    actual = findvar(expr, "x")
    # I don't care about the order of the elements of this list.
    expect_equal(actual, list(c(2, 2, 2), 3))

    # Don't match character vectors
    expr = quote(paste("x", "y"))
    expect_equal(findvar(expr, "y"), list())

    expr = parse(text = '
        d = read.csv("data.csv")
        hist(d[, 2])
    ')
    actual = findvar(expr, "read.csv")

    expect_equal(actual, list(c(1, 3, 1)))

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


test_that("only_literals", {

    expect_true(only_literals(quote(1:5)))

    expect_true(only_literals(quote(c(1, 4))))

    expect_false(only_literals(quote(f(3))))

    expect_false(only_literals(quote(1:n)))

})


if(FALSE){

expr = parse(text = "
    # Testing code:
    n = 100000L
    p = 10L
    x = matrix(1:(n*p), ncol = p)
    x
    nitenite = function(x) Sys.sleep(0.01)
    colmaxs = apply(x, 2, max)
    apply(x, 2, nitenite)
")

# Seems to work fine
expr_out =  parallelize_script(expr)

e = lapply(expr, CodeDepends::getInputs)

lapply(e, function(x) x@inputs)

}
