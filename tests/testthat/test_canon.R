

test_that("names_to_index", {

    code = quote(mtcars$mpg)
    transformed = names_to_index(code, colnames(mtcars))

    expect_identical(mtcars[, 1], transformed)

})


