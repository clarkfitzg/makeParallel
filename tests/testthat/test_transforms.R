context("transforms")

#options(error = recover)

test_that("Basic transformation to parallel", {

    expr = quote(lapply(f, x))
    target = quote(parallel::mclapply(f, x)) 
    actual = parallelize_first_apply(expr)

    expect_equal(actual, target)

    expr = quote(y <- lapply(f, x))
    target = quote(y <- parallel::mclapply(f, x)) 
    actual = parallelize_first_apply(expr)

    expect_equal(actual, target)

})


