oldcode = parse(text = "
    v1 = 'foo1'
    v2 = 'foo2'
    x <- paste0(v1, v1)
    y <- paste0(v2, v2)
    xy <- paste0(x, y)
")


test_that("Components of task parallel inference.", {

    g = dependGraph(oldcode)
    s = schedule(g)
    newcode = generate(s)

    expect_s4_class(g, "DependGraph")
    expect_s4_class(s, "Schedule")
    expect_s4_class(newcode, "GeneratedCode")

    plot(s)

    write(newcode, "ex.R")
    expect_true(file.exists("ex.R"))

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

    # The first two lines will be assigned to different processors, so
    # three transfers should happen regardless of which processor evaluates
    # the last line.
    expect_equal(3, nrow(out$schedule$transfer))

})


test_that("whole workflow on files", {

    task_parallel("example.R")
    expect_true(file.exists("gen_example.R"))

    expect_error(task_parallel("example.R"), "exists")

    task_parallel("example.R", overwrite = TRUE)

    rm("gen_example.R")

    task_parallel("example.R", output_file = "ex.R")
    expect_true(file.exists("ex.R"))
    rm("ex.R")

    task_parallel("example.R", gen_script_prefix = "GEN")
    expect_true(file.exists("GENexample.R"))
    rm("GENexample.R")

})
