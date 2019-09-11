# Testing the data source inference.

library(makeParallel)

out = makeParallel("
dt = read.fwf('dates.txt', widths = 10)
d = as.Date(vals[, 1])
print(range(d))
", scheduler = scheduleDataParallel
)


# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

# Verify that the DataSource is correctly inferred.

} 
