library(makeParallel)

# An example of a user provided custom reduce function.
naiveMeanReduce = reduceFun("mean"
    , summary = function(data) list(length = length(data), sum = sum(data))
    , combine = function(...)
    {
        args = list(...)
        lengths = sapply(args, `[[`, "length")
        sums = sapply(args, `[[`, "sum")
        list(length = sum(lengths), sum = sum(sums))
    }
    , query = function(s) s$sum / s$length
    )


files = list.files("single_numeric_vector", pattern = "*.rds", full.names = TRUE)

# Can surely do this for the user
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(varName = "x0"
    , files = files
	, sizes = sizes
	, readFuncName = "readRDS"
    )

outFile = "gen/two_blocks.R"

out = makeParallel("
x = sin(x0)
result = mean(x)
saveRDS(result, 'gen/result_custom_reduce.rds')
"
, data = x_desc
, scheduler = scheduleDataParallel
, platform = parallelLocalCluster()
, chunkFuncs = c("sin")
, reduceFuncs = list(naiveMeanReduce)
, outFile = outFile
, overWrite = TRUE
)


# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

    rr = 'gen/result_custom_reduce.rds'
    unlink(rr)
    source(outFile)

    result = readRDS(rr)
    # A cleaner way to test this would be to test that both the serial schedules and the parallel ones get the same result.
    expected = readRDS("expected/result_custom_reduce.rds")

    expect_equal(result, expected)

    s = schedule(out)
    block_class = sapply(s@blocks, class)

    expect_true("ReduceBlock" %in% block_class)

}
