test_that("simple case of chunked input data descriptions", {

    setwd("map_reduce_example")
    source("vector_transform.R")

    rr = "result.rds"
    unlink(rr)
    source(outFile)

    result = readRDS(rr)

    expect_equal(result, 0)

})
