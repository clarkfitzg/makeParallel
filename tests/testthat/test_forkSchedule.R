test_that("fork schedule", {

    code = parse(text = "
    x = foo()
    y = bar()
    foobar(x, y)
    ")

    g = inferGraph(code, time = c(2, 3, 1))

    s = scheduleFork(g)

    stop("
I have to decide better how to represent and test this, but
it's not working now. One of these should fork.
         ")

    plot(s)

})


test_that("Helper functions", {

    schedule = c(1, 2, 3, 4, 5, 3, 6)

    expect_equal(blockSplit(4, schedule),
        list(before = c(1, 2, 3)
             , hasnode = c(4, 5)
             , after = c(3, 6)
    ))

    expect_equal(blockSplit(1, schedule),
        list(before = integer()
             , hasnode = c(1, 2)
             , after = c(2, 3, 4, 5, 3, 6)
    ))


})
