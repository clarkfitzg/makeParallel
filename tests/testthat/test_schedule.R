test_that("Components of task parallel inference.", {

    oldcode = parse(text = "
        v1 = 'foo1'
        v2 = 'foo2'
        x <- paste0(v1, v1)
        y <- paste0(v2, v2)
        xy <- paste0(x, y)
    ")

    graph = expr_graph(oldcode)

    plan = minimize_start_time(oldcode, graph)

    expect_s3_class(plan, "schedule")

    plot(plan)

    newcode = generate_snow_code(oldcode, plan)

})
