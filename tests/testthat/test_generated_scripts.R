expect_generated = function(script)
{
    outfile = paste0(basename(script), ".log")
    p = autoparallel(script)

    # Serial
    #eval(p$input_code)
    system2("Rscript", script)
    expected = readLines(outfile)

    # Parallel
    #eval(parse(text = p$output_code))
    system2("Rscript", p$gen_file_name)
    actual = readLines(outfile)
    
    expect_equal(actual, expected)
}


test_that("Generated code from simple examples actually executes", {

    scripts = Sys.glob("testthat/scripts/script*.R")

    #expect_generated(scripts[1])

    lapply(scripts, expect_generated)

})
