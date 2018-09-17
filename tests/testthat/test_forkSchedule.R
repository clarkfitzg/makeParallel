test_that("fork schedule", {

    code = parse(text = "
    x = foo()
    y = bar()
    foobar(x, y)
    ")

    g = inferGraph(code, time = c(2, 3, 1))

    scheduleForkSeq = scheduleFork

    s = scheduleForkSeq(g, overhead = 1e-3)

    # Exactly one statement should be forked and thus appear twice.
    expect_true(xor(sum(s == 1) == 2, sum(s == 2) == 2))

    plot(s)

})


test_that("Helper functions", {

    schedule = c(1, 2, 3, 4, 5, 3, 6)

    expect_equal(forkSplit(4, schedule),
        list(before = c(1, 2, 3)
             , hasnode = c(4, 5)
             , after = c(3, 6)
    ))

    expect_equal(forkSplit(1, schedule),
        list(before = integer()
             , hasnode = c(1, 2)
             , after = c(3, 4, 5, 3, 6)
    ))


})
