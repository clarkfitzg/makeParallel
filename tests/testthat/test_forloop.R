test_that("for loop to mclapply", {

    loop1 = quote(for(i in x){
        f(i)
    })

    actual = forloop_to_lapply(loop1)

    expected = quote(lapply(x, function(i = NULL){f(i)}))

    # Can't be parallelized
    loop2 = quote(for(i in x){
        y = f(y)
    })

    expect_equal(forloop_to_lapply(loop2), loop2)

    skip("TODO: Update same_expr to actually test expression equality.")
    expect_true(same_expr(actual, expected))
})
