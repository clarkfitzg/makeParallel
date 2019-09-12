# Thu Sep 12 10:31:46 PDT 2019
#
# Experimenting to see what makeParallel can currently do with the PEMS example
#
# To actually run we need:
#
# 1. To only read the necessary columns 


library(makeParallel)

files = list.files("~/data/pems"
                   , pattern = "d04_text_station_raw_2016_08_2*"
                   , full.names = TRUE
                   )
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(varName = "x"
    , files = files
    , sizes = sizes
    , readFuncName = "read.csv"
    )

outFile = "gen2.R"

out = makeParallel("pems.R"
, data = x_desc
, nWorkers = 2L
, scheduler = scheduleDataParallel
, platform = parallelLocalCluster()
, chunkFuncs = c("[", "lapply")
, outFile = outFile
, overWrite = TRUE
)
