library(testthat)
library(autoparallel)


expect_generated = function(script, ...)
{
    cat(sprintf("Testing %s\n", script))

    # Check that the output of the file is the same for the serial script
    # and the generated script.

    outfile = paste0(basename(script), ".log")
    serfile = paste0("expected_", outfile)
    p = autoparallel(script, ...)

    pdf(paste0(script, ".pdf"))
    plot(p$schedule)
    dev.off()

    # Serial
    source(script)
    file.rename(outfile, serfile)
    expected = readLines(serfile)

    # Parallel
    # Generated scripts have a cluster `cls`. It needs to be cleaned up if
    # something fails midway through.
    on.exit(try(parallel::stopCluster(cls), silent = TRUE))
    source(p$gen_file_name)
    actual = readLines(outfile)
    
    expect_equal(actual, expected)

    cat(sprintf("Pass %s\n\n", script))
}


test_that("expect_generated fails when it should fail.", {
    # That's right, this is a test of the tests :)

    expect_error(expect_generated("fail.R")
        , regexp = "non-numeric argument to binary operator")

})


test_that("Generated code from simple examples actually executes", {

    #pkg_root = system.file(package = "autoparallel")
    scripts = Sys.glob("script*.R")

    #scripts = system.file("inst", "generated", package = "autoparallel")

    # First do all of them with defaults
    lapply(scripts, expect_generated)

    # Then pass in some extra arguments
    expect_generated("script3.R", maxworkers = 3)

})
