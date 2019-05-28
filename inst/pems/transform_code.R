library(makeParallel)
d = dataFiles(dir = "stationID"
    , format = "text"
    , Rclass = "data.frame"
    , varname = "pems"
    , delimiter = ","
    , splitColumn = "station"
    , header = FALSE
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
p = platform(OS.type = "unix", workers = 10L)

# The named list for the data argument means that the symbol 'pems' in the code corresponds to the data in 'pems_ds'.
# makeParallel("pems.R", data = list(pems = pems_ds), scheduler = scheduleTaskList, workers = 10L)

# It's more convenient at the moment for me to use the varname in the object.
out = makeParallel("pems.R", data = d, platform = p, scheduler = scheduleTaskList)

# Could use a more convenient way to extract this code
tcode = schedule(out)@graph@code

writeCode(tcode[-c(3,4)], "intermediate_transformed_code.R")
