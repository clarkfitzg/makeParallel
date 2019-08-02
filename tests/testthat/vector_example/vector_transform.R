# TODO: Write the narrative for what's going on here, what does it represent / exemplify?
# Tell what's manual and will be automated later.

# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)

fnames = list.files(pattern = "x[1-4]\\.rds")

# Description of the data
# TODO: Infer this
#   Add the number of rows or data sizes to motivate
d = ChunkLoadFunc(read_func_name = "readRDS", read_args = fnames, varname = "x", combine_func_name = "rbind")

# x.csv (is chunked as) x1.csv, x2.csv, x3.csv, x4.csv
# Schedule based on size of files

# TODO: Add this to the example
# x.csv (is chunked as) x1.csv = 200 rows, x2.csv = 300 rows, etc.

out = makeParallel('
#    x = readRDS("x1.rds")
    y = foo(x[, "y"])
    y2 = 4 * y / 2
    2 * 3
# TODO: saveRDS(y2, "y2.rds")
', scheduler = scheduleVector, data = d, nWorkers = 3L, save_var = "y2", vector_funcs = c("foo", "/"))

writeCode(out, "vector_actual_generated.R", overWrite = TRUE)
