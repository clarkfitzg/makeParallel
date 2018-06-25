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

    fn = "ex.R"
    try(unlink(fn))
    writeCode(newcode, fn)
    expect_true(file.exists(fn))

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

    out = makeParallel(code, scheduler = scheduleTaskList)

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

    out = makeParallel(exfile, scheduler = scheduleTaskList, maxWorker = 3)

    expect_s4_class(out, "GeneratedCode")

    plot(schedule(out))

    expect_true(file(out))

    expect_true(file.exists(genfile))

    # 'Catching different types of errors' - This would make a nice blog post.
    e = tryCatch(makeParallel(exfile), error = identity)
    expect_true(is(e, "FileExistsError"))

    makeParallel(exfile, overWrite = TRUE)
    unlink(genfile)

    fname = "some_file_created_in_test.R"
    out = makeParallel(exfile, scheduler = scheduleTaskList, file = fname)
    expect_true(file.exists(fname))
    expect_equal(fname, file(out))
    unlink(fname)

    out = makeParallel("example.R", scheduler = scheduleTaskList, prefix = "GEN")
    fn = "GENexample.R"
    expect_true(file.exists(fn))
    expect_equal(fn, file(out))
    unlink(fn)

})
