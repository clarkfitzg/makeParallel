# Testing the data source inference.

library(makeParallel)

out = makeParallel("range_of_dates.R", scheduler = scheduleDataParallel)

d = dataSource(out)

writeCode(out, "gen_range_of_dates.R", overWrite = TRUE)

source("gen_range_of_dates.R")



# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

script = "
dt = read.fwf('dates.txt', widths = 10L)
d = as.Date(vals[, 1])
rd = range(d)
print(rd)
"

out = makeParallel(script, scheduler = scheduleDataParallel)

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
    # The package code cannot find this.
    # Hence the need to make the function handler list available.

    inferDataSourceFromCall.read.fwf_Call = function(expr, ...) "Boom Boom!"

}
