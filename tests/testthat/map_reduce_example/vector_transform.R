# See clarkfitzthesis/tex/vectorize document to see what's going on.

# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)


files = c("small1.rds", "big.rds", "small2.rds")
# Can surely do this for the user
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(files = files
	, sizes = sizes
	, readFuncName = "readRDS"
    )

outFile = "pmin.R"

out = makeParallel("

    y = sin(x)
    result = min(y)
    saveRDS(result, 'result.rds')
"
, data = list(x = x_desc)
, nWorkers = 2L
, scheduler = scheduleVector
, known_vector_funcs = "sin"
, outFile = outFile
, overWrite = TRUE
)


# Testing
############################################################

# Check that the load balancing happens.
stopifnot(schedule(out)@assignmentIndices == c(1, 2, 1))
