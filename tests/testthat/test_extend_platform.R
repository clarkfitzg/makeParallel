library(makeParallel)

POSIXLocalCluster = setClass("POSIXLocalCluster", contains = "ParallelLocalCluster")

msg = "Yay right method"

setMethod("generate", signature(schedule = "DataLoadBlock", platform = "ParallelLocalCluster", data = "ChunkDataFiles"),
function(schedule, platform, data)
{
    stop(msg)
})

d = ChunkDataFiles(files = c("a.csv", "b.csv"), sizes = c(1, 2), readFuncName = "read.csv", varName = "x")
p = POSIXLocalCluster(nWorkers = 1L, name = "cls")

expect_error(
makeParallel("lapply(x, f)", data = d
             , platform = p
             , scheduler = scheduleDataParallel
             , chunkFuncs = "lapply"
             )
, regexp = msg)
