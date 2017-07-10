context("parallelize")


test_that("basics with default", {

    # Looks like this is required to get around whatever testthat is doing
    assign("x", list(letters, LETTERS, 1:10), envir = .GlobalEnv)

    do = parallelize("x")
    actual = do(lapply(x, head))

    expect_identical(actual, lapply(x, head))

})
