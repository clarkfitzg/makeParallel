context("transforms")

test_that("Basic transformation to parallel", {

    expr = parse(text = "lapply(f, x)")
    target = parse(text = "parallel::mclapply(f, x)")
    actual = data_parallel(expr)$output_code

    expect_equal(actual, target)

    expr = parse(text = "y <- lapply(f, x)")
    target = parse(text = "y <- parallel::mclapply(f, x)")
    actual = data_parallel(expr)$output_code
    expect_equal(actual, target)

    expr = parse(text = "f(a, b)")
    actual = data_parallel(expr)$output_code
    expect_equal(actual, expr)

})


test_that("Nested transformation", {

    expr = parse(text = "lapply(lapply(x, f), g)")
    target = parse(text = "parallel::mclapply(lapply(x, f), g)")
    actual = data_parallel(expr)$output_code
    expect_equal(actual, target)

})
