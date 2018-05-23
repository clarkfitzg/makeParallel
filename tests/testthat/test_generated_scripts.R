expect_generated = function(script, ...)
{
    # Check that the output of the file is the same for the serial script
    # and the generated script.

    outfile = paste0(basename(script), ".log")
    serfile = paste0("expected_", outfile)
    p = autoparallel(script, ...)

    pdf(paste0(script, ".pdf"))
    plot(p$schedule)
    dev.off()

    # Serial
    #eval(p$input_code)
    #e = system2("Rscript", c(script, "--vanilla"))
    e = source(script)
    file.rename(outfile, serfile)
    expected = readLines(serfile)

    # Parallel
    #eval(parse(text = p$output_code))
    system2("Rscript", p$gen_file_name)
    actual = readLines(outfile)
    
    expect_equal(actual, expected)
}


test_that("Generated code from simple examples actually executes", {

    scripts = Sys.glob("testthat/scripts/script*.R")

    # First do all of them with defaults
    lapply(scripts, expect_generated)

    expect_generated("testthat/scripts/script3.R")

    # Then pass in some extra arguments
    expect_generated("testthat/scripts/script3.R", maxworkers = 3)

})
