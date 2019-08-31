# See clarkfitzthesis/tex/vectorize document to see more details for what's going on, what this is working towards.
#

# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)

# We need the files in this order to check the load balancing works.
files = paste0("single_numeric_vector/", c("small1", "big", "small2"), ".rds")

# Can surely do this for the user
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(varName = "x"
    , files = files
	, sizes = sizes
	, readFuncName = "readRDS"
    )

outFile = "gen/map_reduce.R"

out = makeParallel("
    y = sin(x)
    result = min(y)
    saveRDS(result, 'gen/result_map_reduce.rds')
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
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

    # Check that the load balancing happens.
    expect_equal(schedule(out)@assignmentIndices, c(1, 2, 1))

    rr = "gen/result_map_reduce.rds"
    unlink(rr)
    source(outFile)

    result = readRDS(rr)

    expect_equal(result, 0)

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
