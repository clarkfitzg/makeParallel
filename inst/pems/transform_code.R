library(makeParallel)

# Describing a data source
# Needs to express that the files are split based on the station ID
#
# fun: The first argument is the name of a function
#		Another way of doing this is to say that it's a delimited text file, and then pick the function.
# args: Vector of arguments for the first argument.
#       Calling fun(args[[i]]) loads the ith chunk.
# ------------ Everything after is optional ------------
# class: Class of the resulting object.
#       We can support common ones like vectors and data frames, and potentially allow user defined ones here too.
# splitColumn: Name of a column that defines the chunks.
#       Here it means that each chunk will have all the values in the data with one particular value of the column.
#		This tells us if the data are already organized for a particular GROUP BY computation.
# columns: named vector with columns and classes of the table
# colClasses: Classes of the columns (see read.table)
#
pems_ds = dataSource("read.csv", args = list.files("stationID"), class = "data.frame", splitColumn = "station",
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
)


# The named list for the data argument means that the symbol 'pems' in the code corresponds to the data in 'pems_ds'.
makeParallel("pems.R", data = list(pems = pems_ds), workers = 10L)
