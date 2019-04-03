test_that("simple case of chunked input data descriptions", {

    incode = parse(text = "
        y = 2L * x
    ", keep.source = FALSE)

    xfile1 = tempfile()
    xfile2 = tempfile()

    saveRDS(1:5, xfile1)
    saveRDS(6:10, xfile2)

    # What is bothering me?
    # I'm going to have to evaluate and deparse the list of arguments to insert them into the script.
    # This sounds dangerous.

    xdescription = ChunkDataSource(fun = readRDS, args = list(xfile1, xfile2))

    out = makeParallel(incode, data = list(x = xdescription))

    outcode = writeCode(out)

    eval(outcode)

    y_actual = readRDS(yfile)

    # symbols x, y should be available after we evaluate the code
    expect_identical(y, y_actual, 2L * x)

})
