context("distribute")

# distribute works off variables in the global environment
# testthat does some other things here.
assign("y", list(letters, LETTERS, 1:10), envir = .GlobalEnv)


test_that("basics with default", {

    do = distribute(y)

    actual = do(lapply(y, head))

    expect_identical(actual, lapply(y, head))

    head2 = function(y) y[1:2]
    assign("head2", head2, envir = .GlobalEnv)

    actual = do(lapply(y, head2))

    expect_identical(actual, lapply(y, head2))

    stop_cluster(do)

})


test_that("finds global variables", {

    do = distribute(y, spec = 2L)
    # assigning n must happen after cluster creation, otherwise forking
    # will send n
    assign("n", 10, envir = .GlobalEnv)
    actual = do(n)

    expect_identical(actual, c(n, n))

    stop_cluster(do)
})


test_that("splits data frames into groups of rows", {

    do = distribute(iris)
    dims = do(dim(iris))

    expect_equal(dims, c(75, 5, 75, 5))
    stop_cluster(do)
})
