# See clarkfitzthesis/tex/vectorize document to see more details for what's going on, what this is working towards.
#


# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)


files = c("small1.rds", "big.rds", "small2.rds")
# Can surely do this for the user
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(varName = "x"
    , files = files
	, sizes = sizes
	, readFuncName = "readRDS"
    )

outFile = "pmin.R"

out = makeParallel("
    y = sin(x)
    result = min(y)
    saveRDS(result, 'result.rds')
"
, data = x_desc
, nWorkers = 2L
, scheduler = scheduleDataParallel
, platform = parallelLocalCluster()
, chunkableFuncs = "sin"
, outFile = outFile
, overWrite = TRUE
)


# Test code
if(get0(TEST_FLAG, ifnotfound = FALSE)){
    library(testthat)

    # Check that the load balancing happens.
    expect_equal(schedule(out)@assignmentIndices, c(1, 2, 1))


}



if(FALSE){
    # Duncan's example of fusing lapply's works just fine.

    s = makeParallel("
        y = lapply(x, sin)
        y2 = sapply(y, function(x) x^2)
        #ten = 10
        y3 = log(y2 + 2, base = 10)
        result = min(y3)
    "
    , data = list(x = x_desc)
    , nWorkers = 2L
    , scheduler = scheduleDataParallel
    , chunkableFuncs = c("lapply", "sapply", "log", "+")
    , outFile = "lapply_example.R"
    , overWrite = TRUE
    )

    schedule(s)@vectorIndices

    eval(s@code)

}
