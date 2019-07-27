test_that("simple case of chunked input data descriptions", {

    first_generated_file = "y2_1.rds"
    unlink(first_generated_file)
    setwd("vector_example")
    source("vector_transform.R")
    source("vector_actual_generated.R")
    y2_1 = readRDS(first_generated_file)
    expect_equal(y2_1[[1]], 2)

})
