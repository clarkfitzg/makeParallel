# TODO: Write the narrative for what's going on here, what does it represent / exemplify?
# Tell what's manual and will be automated later.

# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)

fnames = list.files(pattern = "x[1-4]\\.rds")

# Description of the data
d = ChunkLoadFunc(read_func_name = "readRDS"
                  , read_args = fnames
                  , varname = "x"
                  , combine_func_name = "rbind"
                  , split_column_name = "y"
                  , column_names = c(y = 1L, z = 2L)
                  , sizes = c(10, 5, 5, 10)
                  )


# TODO: Grow the example by scheduling based on size of files
# x.csv (is chunked as) x1.csv = 200 rows, x2.csv = 300 rows, etc.

out = makeParallel('
    f = function(grp){
        median_z = median(grp[, "z"])
        data.frame(y = grp[1L, "y"], median_z = median_z)
    }
    result = by(x, x[, "y"], f)
    saveRDS(result, "result.rds")
', scheduler = scheduleDataParallel, data = d, nWorkers = 3L)

writeCode(out, "vector_actual_generated.R", overWrite = TRUE)
