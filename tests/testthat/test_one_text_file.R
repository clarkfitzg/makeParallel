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
d1 = dataSource(quote(
    dt <- read.fwf('dates.txt', widths = 10L)
))

# Discovered in the original code by makeParallel
d2 = dataSource(out)

expect_equal(d0, d1)

expect_equal(d0, d2)

} 


if(FALSE){
    # This is an extension mechanism, so could test it.
    # Ugly though.
    
    inferDataSourceFromCall.read.csv_Call = function(expr, ...) "Boom!"

    tst = dataSource(quote(
        dt <- read.csv('dates.txt', widths = 10L)
    ))

    # This is what Duncan was talking about where you actually have to make the method available on the search path.
    # The pacakage code cannot find this.
    # Hence the need to make the function handler list available.

    inferDataSourceFromCall.read.fwf_Call = function(expr, ...) "Boom Boom!"

}
