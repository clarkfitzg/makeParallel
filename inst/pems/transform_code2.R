# Thu Sep 12 10:31:46 PDT 2019
#
# Experimenting to see what makeParallel can currently do with the PEMS example
#
# To actually run we need:
#
# 1. To only read the necessary columns 


library(makeParallel)

#files = list.files("~/data/pems"
#                   , pattern = "d04_text_station_raw_2016_08_2*"
#                   , full.names = TRUE
#                   )

files = list.files("grouped_by_stationID"
        , pattern = "head*.csv"
        , full.names = TRUE)


# TODO: Come back here and work on debugging this.
pems_data = ChunkDataFiles(varName = "pems"
    , files = files
    , readFuncName = "read.csv"
    , col.names = c(timeperiod = "character", station = "integer"
    , flow1 = "integer", occupancy1 = "numeric", speed1 = "numeric"
    , flow2 = "integer", occupancy2 = "numeric", speed2 = "numeric"
    , flow3 = "integer", occupancy3 = "numeric", speed3 = "numeric"
    , flow4 = "integer", occupancy4 = "numeric", speed4 = "numeric"
    , flow5 = "integer", occupancy5 = "numeric", speed5 = "numeric"
    , flow6 = "integer", occupancy6 = "numeric", speed6 = "numeric"
    , flow7 = "integer", occupancy7 = "numeric", speed7 = "numeric"
    , flow8 = "integer", occupancy8 = "numeric", speed8 = "numeric"
    ))


outFile = "gen2.R"

out = makeParallel("pems.R"
, data = pems_data
, nWorkers = 2L
, scheduler = scheduleDataParallel
, platform = parallelLocalCluster()
, chunkFuncs = c("[", "lapply")
, outFile = outFile
, overWrite = TRUE
)

s = schedule(out)
