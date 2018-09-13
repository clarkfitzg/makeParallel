
test_that("fork schedule", {

    code = parse(text = "
    x = foo()
    y = bar()
    foobar(x, y)
    ")

    g = inferGraph(code, time = c(2, 3, 1))

    s = scheduleFork(g)

    plot(s)

})
