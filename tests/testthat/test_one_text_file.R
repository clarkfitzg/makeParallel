# Testing the data source inference.

library(makeParallel)

out = makeParallel("
dt = read.fwf('dates.txt', widths = 10L)
d = as.Date(vals[, 1])
print(range(d))
", scheduler = scheduleDataParallel
)


# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

# Manual specification
d0 = FixedWidthFiles(varName = "dt", files = "dates.txt", widths = 10L)

# Inference on a single call
d1 = inferDataSource(quote(
    dt <- read.fwf('dates.txt', widths = 10L)
))

# Discovered by makeParallel
d2 = dataSource(out)

expect_equal(d0, d1)

expect_equal(d0, d2)

} 
