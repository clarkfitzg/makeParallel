oldcode = parse(text = "
    v1 = 'foo1'
    v2 = 'foo2'
    x <- paste0(v1, v1)
    y <- paste0(v2, v2)
    xy <- paste0(x, y)
")


test_that("Components of task parallel inference.", {

    graph = task_graph(oldcode)

    plan = min_start_time(graph)

    expect_s3_class(plan$schedule, "schedule")

    plot(plan$schedule)

    newcode = gen_socket_code(plan)

})


test_that("run_and_measure", {

    graph = run_and_measure(task_graph(oldcode))

    expect_equal(graph$task_graph$size[1], as.numeric(object.size("foo1")))

})


test_that("Multiple assignment in single expression", {

    code = parse(text = "
        x = y = z = 1
        a = b = c = 2
        f(x, y, z, a, b, c)
    ")

    out = task_parallel(code)

    expect_equal(3, nrow(out$schedule$transfer))

})
