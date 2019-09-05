library(makeParallel)

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
x = sin(x0)             # ParallelBlock 1
y = cos(x0)
z = ceiling(x)
mx = median(x)          # SerialBlock 1
x2 = x + y + z - mx     # ParallelBlock 2
result = max(x2)        # Reduce 1
saveRDS(result, 'gen/result_two_blocks.rds') # SerialBlock2
"
, data = x_desc
, scheduler = scheduleDataParallel
, platform = parallelLocalCluster()
, chunkableFuncs = c("sin", "cos", "+", "-", "ceiling")
, outFile = outFile
, overWrite = TRUE
)


# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

    rr = "gen/result_two_blocks.rds"
    unlink(rr)
    source(outFile)

    result = readRDS(rr)
    # A cleaner way to test this would be to test that both the serial schedules and the parallel ones get the same result.
    expected = readRDS("expected/result_two_blocks.rds")

    expect_equal(result, expected)

    s = schedule(out)
    block_class = sapply(s@blocks, class)
    expect_equal(sum(block_class == "ParallelBlock"), 2L)

}
