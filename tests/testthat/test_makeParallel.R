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

    fn = tempfile()
    writeCode(newcode, fn)
    expect_true(file.exists(fn))
    unlink(fn)

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
    ", keep.source = FALSE)

    out = makeParallel(code, scheduler = scheduleTaskList)

    # This test is specific to the implementation, and may need to change.
    # The first two lines will be assigned to different processors, so
    # three transfers should happen regardless of which processor evaluates
    # the last line.
    trans = schedule(out)@transfer

    expect_equal(3, nrow(trans))

})


test_that("whole workflow on files", {

    exfile = file.path(temp_dir, "mp_example.R")
    oldscript = system.file("examples/mp_example.R", package = "makeParallel")
    file.copy(from = oldscript, to = exfile)
    genfile = file.path(temp_dir, "gen_mp_example.R")

    out = makeParallel(exfile, file = TRUE, scheduler = scheduleTaskList, maxWorker = 3)

    expect_s4_class(out, "GeneratedCode")

    plot(schedule(out))

    expect_equal(file(out), genfile)

    expect_true(file.exists(genfile))

    # 'Catching different types of errors' - This would make a nice blog post.
    e = tryCatch(makeParallel(exfile, file = genfile), error = identity)
    expect_true(is(e, "FileExistsError"))

    makeParallel(exfile, file = TRUE, overWrite = TRUE)

    unlink(genfile)
    makeParallel(exfile, file = FALSE)
    expect_false(file.exists(genfile))

    fname = file.path(temp_dir, "some_file_created_in_test.R")
    out = makeParallel(exfile, scheduler = scheduleTaskList, file = fname)
    expect_true(file.exists(fname))
    expect_equal(fname, file(out))

    out = makeParallel(exfile, file = TRUE, scheduler = scheduleTaskList, prefix = "GEN")
    fn = file.path(temp_dir, "GENmp_example.R")
    expect_true(file.exists(fn))
    expect_equal(fn, file(out))

})
