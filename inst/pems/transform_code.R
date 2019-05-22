library(makeParallel)

pems_ds = dataFiles(dir = "stationID", format = "text", Rclass = "data.frame"
    , splitColumn = "station", header = FALSE
	, columns = c(timeperiod = "character", station = "integer"
		, flow1 = "integer", occupancy1 = "numeric", speed1 = "numeric"
		, flow2 = "integer", occupancy2 = "numeric", speed2 = "numeric"
		, flow3 = "integer", occupancy3 = "numeric", speed3 = "numeric"
		, flow4 = "integer", occupancy4 = "numeric", speed4 = "numeric"
		, flow5 = "integer", occupancy5 = "numeric", speed5 = "numeric"
		, flow6 = "integer", occupancy6 = "numeric", speed6 = "numeric"
		, flow7 = "integer", occupancy7 = "numeric", speed7 = "numeric"
		, flow8 = "integer", occupancy8 = "numeric", speed8 = "numeric"
	)
)

# The named list for the data argument means that the symbol 'pems' in the code corresponds to the data in 'pems_ds'.
makeParallel("pems.R", data = list(pems = pems_ds), workers = 10L)
