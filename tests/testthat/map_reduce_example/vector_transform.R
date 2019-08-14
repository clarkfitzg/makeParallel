# See clarkfitzthesis/tex/vectorize document to see what's going on.

# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)

x_desc = ChunkLoadFunc(read_func_name = "readRDS"
    , read_args = c("x1.rds", "x2.rds", "x3.rds")
    , combine_func_name = "c"
    )

out = makeParallel("

    y = sin(x)
    result = min(y)
    saveRDS(result, 'result.rds')
"
, data = list(x = x_desc)
, nWorkers = 2L
, scheduler = scheduleVector
, known_vector_funcs = "sin"
, outFile = "pmin.R"
)

