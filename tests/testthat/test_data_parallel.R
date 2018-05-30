context("transforms")

test_that("Basic transformation to parallel", {

    expr = quote(lapply(f, x))
    target = quote(parallel::mclapply(f, x)) 
    actual = ser_apply_to_parallel(expr)
    expect_equal(actual, target)

    expr = quote(y <- lapply(f, x))
    target = quote(y <- parallel::mclapply(f, x)) 
    actual = ser_apply_to_parallel(expr)
    expect_equal(actual, target)

    expr = quote(f(a, b))
    actual = parallelize_first_apply(expr)
    expect_equal(expr, actual)

})


test_that("Nested transformation", {

    expr = quote(lapply(lapply(x, f), g))
    target = quote(parallel::mclapply(lapply(x, f), g))
    actual = parallelize_first_apply(expr)
    expect_equal(actual, target)

})
