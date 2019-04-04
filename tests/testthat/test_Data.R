test_that("simple case of chunked input data descriptions", {

    incode = parse(text = "
        y = 2L * x
    ", keep.source = FALSE)

    xfile1 = tempfile()
    xfile2 = tempfile()

    saveRDS(1:5, xfile1)
    saveRDS(6:10, xfile2)

    # Build the expression by pulling the literals out
    e = environment()
    chunk_load_code = as.expression(list(
        substitute(readRDS(xfile1), env=e),
        substitute(readRDS(xfile2), env=e)
    ))

    xdescription = ChunkDataSource()

    out = makeParallel(incode, data = list(x = xdescription))

    outcode = writeCode(out)

    eval(outcode)

    y_actual = readRDS(yfile)

    # symbols x, y should be available after we evaluate the code
    expect_identical(y, y_actual, 2L * x)

})
