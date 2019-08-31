# TODO: Delete this file and fold everything into one folder. It's using the same data.

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
x = sin(x0)             # chunkable 1
mx = median(x)          # general 1
x2 = x - mx             # chunkable 2
result = max(x2)        # reduce 1
saveRDS(result, 'result.rds') # general 2
"
, data = list(x0 = x_desc)
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
