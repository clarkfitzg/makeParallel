library(makeParallel)

# Needs to express that the files are split based on the station ID
#
# fun: The first argument is the name of a function
# args: Vector of arguments for the first argument.
#       Calling fun(args[[i]]) loads the ith chunk.
# class: Class of the resulting object.
#       We can support common ones like vectors and data frames, and potentially allow user defined ones here too.
# splitColumn: Name of a column that defines the chunks.
#       Here it means that fun(args[[i]]) will load one of these chunks,
#       and this chunk will have all the values in the data set
# col.names: Names of the columns (see read.table)
# colClasses: Classes of the columns (see read.table)
#
pems_ds = dataSource("read.csv", args = list.files("stationID"), class = "data.frame", splitColumn = "station")


# The named list for the data argument means that the symbol 'pems' in the code corresponds to the data in 'pems_ds'.
makeParallel("pems.R", data = list(pems = pems_ds), workers = 10L)
