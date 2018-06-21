oldcode = parse(text = "
    v1 = 'foo1'
    v2 = 'foo2'
    x <- paste0(v1, v1)
    y <- paste0(v2, v2)
    xy <- paste0(x, y)
")


test_that("Defaults for generics used in parallelize.", {

    g = inferGraph(oldcode)
    s = schedule(g)
    newcode = generate(s)

    expect_s4_class(g, "DependGraph")
    expect_s4_class(s, "Schedule")
    expect_s4_class(newcode, "GeneratedCode")

    out = writeCode(newcode, "ex.R")
    expect_equal(out, "ex.R")
    expect_true(file.exists("ex.R"))

    unlink("ex.R")

})


test_that("runMeasure", {

    g = runMeasure(oldcode)

    expect_s4_class(g, "MeasuredDependGraph")

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

    exfile = "example.R"
    genfile = "gen_example.R"
    try(unlink(genfile))

    out = parallelize(exfile, scheduler = scheduleTaskList, maxWorker = 3)

    expect_s4_class(out, "GeneratedCode")

    plot(schedule(out))

    expect_equal(genfile, out@outfile)

    expect_true(file.exists(genfile))

    expect_error(parallelize(exfile), "exists")

    parallelize(exfile, overWrite = TRUE)
    unlink(genfile)

    fname = "some_file_created_in_test.R"
    out = parallelize(exfile, scheduler = scheduleTaskList, file = fname)
    expect_true(file.exists(fname))
    expect_equal(fname, out@outfile)
    unlink(fname)

    parallelize("example.R", scheduler = scheduleTaskList, prefix = "GEN")
    expect_true(file.exists("GENexample.R"))
    unlink("GENexample.R")

})
