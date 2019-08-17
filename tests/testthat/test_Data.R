library(makeParallel)

test_that("calls into DataSource classes", {

    fwf_call = quote(read.fwf("foo.txt", widths = c(5, 5, 10)))

    #actual = dataSource(fwf_call)

    #expected = ChunkDataFiles(

})


test_that("simple case of chunked input data descriptions", {

    skip("Dropping data expansion idea for the moment")

    incode = parse(text = "
        y = 2L * x
        m_y = median(y)
    ", keep.source = FALSE)

    xfile1 = tempfile()
    xfile2 = tempfile()

    saveRDS(1:5, xfile1)
    saveRDS(6:10, xfile2)

    # Build the expression by grabbing the literal filenames
    e = list(xfile1 = xfile1, xfile2 = xfile2)
    chunk_load_code = as.expression(list(
        substitute(readRDS(xfile1), e),
        substitute(readRDS(xfile2), e)
    ))

    xdescription = tableChunkData(expr = chunk_load_code, varname = "x", collector = "c")

    # Mon May 27 16:10:48 PDT 2019
    # The issue I'm having now is that I want to use the list signature for expandData.
    # This API below also uses the list signature.
    # In this API each element of the list is a data source.
    # I could dispatch on the class of the elements of the list.
    # But that seems excessive, because I only need it when I read in a bunch of data in the first place.
    out = makeParallel(incode
                       , scheduler = scheduleTaskList
                       , data = list(x = xdescription)
                       , maxWorker = 1L
                       )

    outcode = writeCode(out)

    eval(outcode)

    # These variable names subject to change.
    x = c(x_1, x_2)
    y_out = c(y_1, y_2)

    # Makes y available, writing over previous version
    eval(incode)

    expect_identical(y, y_out)

})
