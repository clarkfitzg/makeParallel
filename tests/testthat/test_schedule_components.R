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

    newcode = gen_snow_code(plan)

})


test_that("run_and_measure", {

    graph = run_and_measure(task_graph(oldcode))

    expect_equal(graph$task_graph$size[1], object.size("foo1"))

})
