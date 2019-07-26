# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)

fnames = list.files(pattern = "x[1-4]\\.rds")

d = ChunkLoadFunc(read_func_name = "readRDS", read_args = fnames, varname = "x", combine_func_name = "rbind")

out = makeParallel('
    y = x[, "y"]
    y2 = 2 * y
    2 * 3
', scheduler = scheduleVector, data = d, save_var = "y2")

writeCode(out, "vector_actual_generated.R", overWrite = TRUE)
