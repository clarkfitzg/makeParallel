test_that("minimal", {

temp_dir = normalizePath(tempdir(), winslash = "/")

    xfile = file.path(temp_dir, "x.rds")

    #xfile = tempfile()
    #xfile = "test.log"
    xdata = 1:5

    browser()

    writeLines(letters, xfile)

    # This exact same pattern works fine within test_makeParallel.
    # Yet it fails here.
    # Why?

    #saveRDS(xdata, xfile)
    #con = gzfile(xfile) 
    #open(con, "wb")
    #saveRDS(xdata, con)

})
