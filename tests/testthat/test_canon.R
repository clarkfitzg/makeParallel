

test_that("names_to_index helper functions", {

    code = quote(dframe$b)

    transformed = dollar_to_index(code, letters)

    expect_identical(dframe[, 2], transformed)

})


