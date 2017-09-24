

test_that("names_to_index helper functions", {

    code = quote(dframe$b)
    transformed = dollar_to_index(code, letters)$statement
    expect_identical(quote(dframe[, 2L]), transformed)

    code = quote(dframe[["b"]])
    transformed = double_to_single_bracket(code, letters)$statement
    expect_identical(quote(dframe[, 2L]), transformed)

    code = quote(dframe[[2L]])
    transformed = double_to_single_bracket(code, letters)$statement
    expect_identical(quote(dframe[, 2L]), transformed)

})


