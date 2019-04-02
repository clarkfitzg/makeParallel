test_that("simple case of input and output data descriptions", {

    incode = parse(text = "
        y = 2L * x
    ", keep.source = FALSE)

    xfile = tempfile()
    yfile = tempfile()

    xdata = 1:5
    saveRDS(xdata, xfile)

    xdescription = DataSource(symbol = "x", fun = readRDS, args = list(file = xfile))
    ydescription = DataSink(symbol = "y", fun = saveRDS, args = list(file = yfile))

    # Could also handle lists of data sources / sinks.
    out = makeParallel(code, data = xdescription, save = ydescription)

    outcode = writeCode(out)

    eval(outcode)

    y_actual = readRDS(yfile)

    # symbols x, y should be available after we evaluate the code
    expect_identical(y, y_actual, 2L * x)

    unlink(c(xfile, yfile))
})
