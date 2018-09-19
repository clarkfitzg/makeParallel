test_that("fork schedule", {

    code = parse(text = "
    x = foo()
    y = bar()
    foobar(x, y)
    ")

    g = inferGraph(code, time = c(2, 3, 1))

    s = scheduleForkSeq(g, overhead = 1e-3)

    # Exactly one statement should be forked and thus appear twice.
    expect_true(xor(sum(s == 1) == 2, sum(s == 2) == 2))

    plot(s)

})


test_that("fork schedule on a larger script", {

    codewall = parse("codewall.R")

    # Some times are large, some not.
    set.seed(8439)
    n = length(codewall)
    times = runif(n)
    epsilon = 1e-4
    times[sample.int(n, size = floor(n/2))] = epsilon

    g = inferGraph(codewall, time = times)

    s = scheduleFork(g)

    # TODO: Write plot method
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
