test_that("for loop to mclapply", {

    loop1 = quote(for(i in x){f(i)})

    actual = forloop_to_lapply(loop1)

    expected = quote(lapply(x, function(i){f(i)}))

    expect_equal(actual, expected)

    # Can't be parallelized
    loop2 = quote(for(i in x){
        y = f(y)
    })

    expect_equal(forloop_to_lapply(loop2), loop2)

    #skip("TODO: Update same_expr to actually test expression equality.")
    #expect_true(same_expr(actual, expected))
})


if(FALSE){

# Try to reproduce a minimal example

    loop = quote(for(i in 1:10){i + 5})

    goal = quote(lapply(x, function(i = NULL){i + 5}))
    actual = goal

    body(goal[[3]])

    # Issue is that I need to go from an actual function to an expression
    # containing a function. Crazy.

}
