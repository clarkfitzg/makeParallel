# Thu Sep 12 10:31:46 PDT 2019
#
# Experimenting to see what makeParallel can currently do with the PEMS example
#
# To actually run we need:
#
# 1. To only read the necessary columns 


library(makeParallel)

nWorkers = 10L
outFile = "gen_subset.R"
nfiles = 50L


files = list.files("/scratch/clarkf/pems/district4"
                   , full.names = TRUE
                   )

# Adding this in an attempt to avoid memory problems.
files = files[seq(nfiles)]


#files = list.files("data"
#        , full.names = TRUE)

columns = c(timeperiod = "character", station = "integer"
    , flow1 = "integer", occupancy1 = "numeric", speed1 = "numeric"
    , flow2 = "integer", occupancy2 = "numeric", speed2 = "numeric"
    , flow3 = "integer", occupancy3 = "numeric", speed3 = "numeric"
    , flow4 = "integer", occupancy4 = "numeric", speed4 = "numeric"
    , flow5 = "integer", occupancy5 = "numeric", speed5 = "numeric"
    , flow6 = "integer", occupancy6 = "numeric", speed6 = "numeric"
    , flow7 = "integer", occupancy7 = "numeric", speed7 = "numeric"
    , flow8 = "integer", occupancy8 = "numeric", speed8 = "numeric"
    )

pems_data = DataFrameFiles(varName = "pems"
    , files = files
    , sizes = file.info(files)$size
    , readFuncName = "read.csv"
    , col.names = names(columns)
    , colClasses = unname(columns)
    , header = FALSE
    )



out = makeParallel("pems.R"
, data = pems_data
, scheduler = scheduleDataParallel
, platform = parallelLocalCluster(nWorkers = nWorkers)
, chunkFuncs = c("[", "lapply")
, outFile = outFile
, overWrite = TRUE
)

s = schedule(out)
