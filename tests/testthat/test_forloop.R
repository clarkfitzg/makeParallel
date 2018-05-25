test_that("for loop to mclapply", {

    loop1 = quote(for(i in x){
        f(i)
    })

    actual = forloop_to_mclapply(loop1)

    expected = quote(parallel::mclapply(x, function(i = NULL){f(i)}))

    expect_true(same_expr(actual, expected))

    # Can't be parallelized
    loop2 = quote(for(i in x){
        y = f(y)
    })

    expect_equal(forloop_to_mclapply(loop2), loop2)

})
