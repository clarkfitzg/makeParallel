# The code to do the actual transformation

source("vector.R")

# Set up some toy data
gen_one = function(i, fname)
{
    d = data.frame(y = i, z = 0)
    saveRDS(d, file = fname)
}
nchunks = 4L
fnames = paste0("x", seq(nchunks), ".rds")
Map(gen_one, seq(nchunks), fnames)


# What follows is what we expect the user of makeParallel to write.
############################################################

d = ChunkLoadFunc(read_func = "readRDS", file_names = fnames, varname = "x", combine_func = "rbind")

code = parse(text = '
    y = x[, "y"]
    y2 = 2 * y
    2 * 3
')

out = makeParallel(code, scheduler = scheduleVector, data = d, save_var = "y2")

writeCode(out, "vector_actual_generated.R", overWrite = TRUE)
