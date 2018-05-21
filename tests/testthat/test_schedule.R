test_that("Components of task parallel inference.", {

    oldcode = parse(text = "
        v1 = 'foo1'
        v2 = 'foo2'
        x <- paste0(v1, v1)
        y <- paste0(v2, v2)
        xy <- paste0(x, y)
    ")

    graph = task_graph(oldcode)

    plan = min_start_time(graph)

    expect_s3_class(plan$schedule, "schedule")

    plot(plan$schedule)

    newcode = gen_snow_code(plan)

    #eval(newcode

})
