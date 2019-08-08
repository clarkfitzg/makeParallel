# See clarkfitzthesis/tex/vectorize document to see what's going on.

# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)

fnames = list.files(pattern = "x[1-4]\\.rds")
x_desc = dataFiles(fnames)

out = makeParallel('

    y = sin(x)
    result = min(y)
    saveRDS(result, "result.rds")
'
, data = list(x = x_desc)
, nWorkers = 3L
, outFile = "pmin.R"
)
