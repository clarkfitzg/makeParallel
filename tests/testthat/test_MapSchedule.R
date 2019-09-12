# Use NSE to make the tests more readable.
generated_code_matches = function(input, expected)
{
    expr = substitute(input)
    desired_expr = as.expression(substitute(expected))
    actual = makeParallel(expr = expr)@code
    expect_equal(actual, desired_expr)
}


test_that("Basic transformation to parallel", {

    skip("plan to deprecate")
    generated_code_matches(lapply(f, x)
        , parallel::mclapply(f, x))

    generated_code_matches(f(a, b)
        , f(a, b))

})


test_that("Nested parallelism", {

    skip("plan to deprecate")
    generated_code_matches(lapply(lapply(x, f), g)
        , parallel::mclapply(lapply(x, f), g))

    generated_code_matches(foo(lapply(x, f), lapply(y, f))
        , foo(parallel::mclapply(x, f), parallel::mclapply(y, f)))

})
