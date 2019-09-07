library(makeParallel)

medianReduce = reduceFun("median"
    , summary = function(data) NULL
    , combine = function(...) NULL
    , query = function(s) NULL
    )

files = list.files("single_numeric_vector", pattern = "*.rds", full.names = TRUE)

# Can surely do this for the user
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(varName = "x0"
    , files = files
	, sizes = sizes
	, readFuncName = "readRDS"
    , fewDistinct = TRUE
    )

outFile = "gen/median_reduce.R"

out = makeParallel("
x = sin(x0)
result = median(x)
saveRDS(result, 'gen/result_median_reduce.rds')
"
, data = x_desc
, scheduler = scheduleDataParallel
, platform = parallelLocalCluster()
, chunkFuncs = c("sin")
, reduceFuncs = list(medianReduce)
, outFile = outFile
, overWrite = TRUE
)


# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

    rr = 'gen/result_median_reduce.rds'
    unlink(rr)
    source(outFile)

    result = readRDS(rr)
    # A cleaner way to test this would be to test that both the serial schedules and the parallel ones get the same result.
    expected = readRDS("expected/result_median_reduce.rds")

    expect_equal(result, expected)

    s = schedule(out)
    block_class = sapply(s@blocks, class)

    expect_true("ReduceBlock" %in% block_class)

}
