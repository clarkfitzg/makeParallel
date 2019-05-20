library(makeParallel)

# Needs to express that the files are split based on the station ID
ds = dataSource(read.csv, args = list.files("stationID"))

makeParallel("pems.R", data = ds, workers = 10L)
