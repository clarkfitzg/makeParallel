context("parallelize")

# parallelize works off variables in the global environment
# testthat does some other things here.
assign("y", list(letters, LETTERS, 1:10), envir = .GlobalEnv)


test_that("basics with default", {

    do = parallelize(y)
    actual = do(lapply(y, head))

    expect_identical(actual, lapply(y, head))

    head2 = function(y) y[1:2]
    assign("head2", head2, envir = .GlobalEnv)

    actual = do(lapply(y, head2))

    expect_identical(actual, lapply(y, head2))
})


test_that("finds global variables", {

    do = parallelize(y, spec = 2L)
    # assigning n must happen after cluster creation, otherwise forking
    # will send n
    assign("n", 10, envir = .GlobalEnv)
    actual = do(n)

    expect_identical(actual, c(n, n))

})
