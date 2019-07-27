message("This code was generated from R by makeParallel version 0.2.0 at 2019-07-27 12:53:36")
library(parallel)
nworkers = 3
assignments = list(1, 2:3, 4)
read_args = c("x1.rds", "x2.rds", "x3.rds", "x4.rds")
cls = makeCluster(nworkers)
clusterExport(cls, c("assignments", "read_args"))
parLapply(cls, seq(nworkers), function(i) assign("workerID", i, globalenv()))
clusterEvalQ(cls, {
    read_args = read_args[assignments[[workerID]]]
    chunks = lapply(read_args, readRDS)
    x = do.call(rbind, chunks)
    {
        y = x[, "y"]
        y2 = 2 * y
    }
    fname = paste0("y2", "_", workerID, ".rds")
    saveRDS(y2, file = fname)
})
2 * 3
