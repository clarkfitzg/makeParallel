expect_generated = function(script, expected_output)
{
    p = autoparallel(script)
    eval(p$code)
    expect_equal(readLines(paste0(script, ".log")
        , readLines(expected_output)))
}


test_that("Generated code from simple examples actually executes", {

    scripts = list.files("testthat/scripts/", pattern )
    expected_logs = list.files("testthat/scripts/expect*.log")

    Map(expect_generated, scripts, expected_logs)

})
