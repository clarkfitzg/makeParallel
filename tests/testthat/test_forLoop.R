# DO NOT add more tests here. Put them in CodeAnalysis

test_that("for loop to lapply", {

    loop1 = quote(for(i in x){f(i)})
    actual = forLoopToLapply(loop1)
    expected = quote(lapply(x, function(i){f(i)}))

    expect_equal(actual, expected)

    # Can't be parallelized
    loop2 = quote(for(i in x){
        y = f(y)
    })

    expect_equal(forLoopToLapply(loop2), loop2)

    loop3 = quote(for(i in x){
        tmp = foo()
        f(tmp, i)
    })
    actual = forLoopToLapply(loop3)
    expected = quote(lapply(x, function(i){
        tmp = foo()
        f(tmp, i)
    }))

    expect_equal(actual, expected)

})


# For testing interactively
#forLoopToLapply = autoparallel:::forLoopToLapply
#debug(autoparallel:::forloop_with_updates)

test_that("assignment inside for loop", {

    loop1 = quote(
    for (i in 1:500){
        tmp = g() 
        output[[i]] = tmp
    })

    expected = quote(
    output[1:500] <- lapply(1:500, function(i) {
        tmp = g() 
        tmp
    }))

    actual = forLoopToLapply(loop1)

    expect_equal(actual, expected)

    # True dependence, can't parallelize
    loop2 = quote(
    for (i in 1:500){
        tmp = g(tmp) 
        x[[i]] = tmp
    })

    actual = forLoopToLapply(loop2)

    expect_equal(actual, loop2)

    # True dependence, can't parallelize
    loop3 = quote(
    for (i in 2:500){
        x[[i]] = g(x[[i - 1]])
    })

    actual = forLoopToLapply(loop3)

    expect_equal(actual, loop3)

})
