# Testing the data source inference.

out = makeParallel("
dt = read.fwf('dates.txt', widths = 10)
d = as.Date(vals[, 1])
print(range(d))
"
)


# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

    # 

} 
