expect_generated = function(script)
{
    outfile = paste0(script, ".log")
    p = autoparallel(script)

    # Serial
    eval(p$input_code)
    expected = readLines(outfile)

    # Parallel
    eval(parse(text = p$output_code))
    actual = readLines(outfile)
    
    expect_equal(actual, expected)
}


test_that("Generated code from simple examples actually executes", {

    scripts = list.files("testthat/scripts/", pattern = "script*.R")

    lapply(scripts, expect_generated)

})
