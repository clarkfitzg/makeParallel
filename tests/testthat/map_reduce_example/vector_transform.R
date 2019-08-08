# See clarkfitzthesis/tex/vectorize document to see what's going on.

# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)

x_desc = dataFiles(files = c("x1.rds", "x2.rds", "x3.rds")
, sizes = c(100, 200, 300)
, readFuncName = "readRDS")

out = makeParallel('

    y = sin(x)
    result = min(y)
    saveRDS(result, "result.rds")
'
, data = list(x = x_desc)
, nWorkers = 2L
, outFile = "pmin.R"
)
