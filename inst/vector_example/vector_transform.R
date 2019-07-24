# The code to do the actual transformation
# That is, what we expect the user of makeParallel to write.

library(makeParallel)

fnames = list.files(pattern = "x[1-4]\\.rds")

d = ChunkLoadFunc(read_func_name = "readRDS", file_names = fnames, varname = "x", combine_func_name = "rbind")

code = parse(text = '
    y = x[, "y"]
    y2 = 2 * y
    2 * 3
')

out = makeParallel(code, scheduler = scheduleVector, data = d, save_var = "y2")

writeCode(out, "vector_actual_generated.R", overWrite = TRUE)
