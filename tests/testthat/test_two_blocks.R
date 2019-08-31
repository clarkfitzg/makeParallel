library(makeParallel)

files = list.files("single_numeric_vector", pattern = "*.rds", full.names = TRUE)

# Can surely do this for the user
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(varName = "x"
    , files = files
	, sizes = sizes
	, readFuncName = "readRDS"
    )

outFile = "gen/two_blocks.R"

out = makeParallel("
x = sin(x0)             # chunkable 1
mx = median(x)          # general 1
x2 = x - mx             # chunkable 2
result = max(x2)        # reduce 1
saveRDS(result, 'gen/result_two_blocks.rds') # general 2
"
, data = x_desc
, nWorkers = 2L
, scheduler = scheduleDataParallel
, chunkableFuncs = c("sin", "-")
, outFile = outFile
, overWrite = TRUE
)


# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){
   
}
