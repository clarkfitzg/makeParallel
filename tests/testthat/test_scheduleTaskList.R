oldcode = parse(text = "
    v1 = 'foo1'
    v2 = 'foo2'
    x <- paste0(v1, v1)
    y <- paste0(v2, v2)
    xy <- paste0(x, y)
")


test_that("Defaults", {

    g = inferGraph(oldcode)

    expect_warning(scheduleTaskList(g), "TimedDependGraph")

})


test_that("Plotting", {

    code = parse(text = "
        x = 1:10
        y = sin(x)
        pdf('sin.pdf')
        plot(x, y)
        dev.off()
        ")

    g = inferGraph(code)

    s = scheduleTaskList(g)

    plot(s)

})
