test_that("simple case of chunked input data descriptions", {

    incode = parse(text = "
        y = 2L * x
    ", keep.source = FALSE)

    xfile1 = tempfile()
    xfile2 = tempfile()

    saveRDS(1:5, xfile1)
    saveRDS(6:10, xfile2)

    # What is bothering me?
    # It's this- how am I going to insert the arguments into a generated script as code?
   
    # I could store the function arguments as R objects, save them alongside the written files,
    # and then load and call them when I need them.
    # Using functions in this way is more general than just assuming we have the full data loaded as R objects.

    # I recall dask has a pretty elegant way of doing this, with tuples and function calls.
 
    xdescription = ChunkDataSource(fun = readRDS, args = list(xfile1, xfile2))

    out = makeParallel(incode, data = list(x = xdescription))

    outcode = writeCode(out)

    eval(outcode)

    y_actual = readRDS(yfile)

    # symbols x, y should be available after we evaluate the code
    expect_identical(y, y_actual, 2L * x)

})
