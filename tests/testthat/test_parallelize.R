oldcode = parse(text = "
    v1 = 'foo1'
    v2 = 'foo2'
    x <- paste0(v1, v1)
    y <- paste0(v2, v2)
    xy <- paste0(x, y)
")


test_that("Defaults for generics used in parallelize.", {

    g = dependGraph(oldcode)
    s = schedule(g)
    newcode = generate(s)

    expect_s4_class(g, "DependGraph")
    expect_s4_class(s, "Schedule")
    expect_s4_class(newcode, "GeneratedCode")

    # TODO: test for task parallel
    #plot(s)

    writeCode(newcode, "ex.R")
    expect_true(file.exists("ex.R"))

    unlink("ex.R")

})


test_that("run_and_measure", {

    graph = run_and_measure(dependGraph(oldcode))

    expect_equal(graph$dependGraph$size[1], as.numeric(object.size("foo1")))

})


test_that("Multiple assignment in single expression", {

    code = parse(text = "
        x = y = z = 1
        a = b = c = 2
        f(x, y, z, a, b, c)
    ")

    out = parallelize(code, scheduler = scheduleTaskList)

    # The first two lines will be assigned to different processors, so
    # three transfers should happen regardless of which processor evaluates
    # the last line.
    trans = schedule(out)@transfer
    expect_equal(3, nrow(trans))

})


test_that("whole workflow on files", {

    parallelize("example.R", scheduler = scheduleTaskList)
    expect_true(file.exists("gen_example.R"))

    expect_error(parallelize("example.R"), "exists")

    parallelize("example.R", overWrite = TRUE)
    unlink("gen_example.R")

    fname = "some_file_created_in_test.R"
    parallelize("example.R", scheduler = scheduleTaskList, output_file = fname)
    expect_true(file.exists(fname))
    unlink(fname)

    parallelize("example.R", scheduler = scheduleTaskList, prefix = "GEN")
    expect_true(file.exists("GENexample.R"))
    unlink("GENexample.R")

})
