context("parallelize")

# parallelize works off variables in the global environment
# testthat does some other things here.
assign("x", list(letters, LETTERS, 1:10), envir = .GlobalEnv)


test_that("basics with default", {

    do = parallelize(x)
    actual = do(lapply(x, head))

    expect_identical(actual, lapply(x, head))

    head2 = function(x) x[1:2]
    assign("head2", head2, envir = .GlobalEnv)

    actual = do(lapply(x, head2))

    expect_identical(actual, lapply(x, head2))
})


test_that("finds global variables", {

    assign("n", 10, envir = .GlobalEnv)

    do = parallelize(x, spec = 2L)
    actual = do(n)

    expect_identical(actual, c(n, n))

})
