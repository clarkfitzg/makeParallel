message(sprintf("This code was generated from R by makeParallel version %s at %s", list(c(0, 2, 0)), 1564011123.68592))
library(parallel)
nworkers = 2
assignments = list(1:3, 4:6)
file_names = c("x1.rds", "x2.rds", "x3.rds", "x4.rds", "y2_1.rds", "y2_2.rds")
cls = makeCluster(nworkers)
clusterExport(cls, c("assignments", "file_names"))
parLapply(cls, seq(nworkers), function(i) assign("workerID", i, globalenv()))
clusterEvalQ(cls, {
    file_names = file_names[assignments[[workerID]]]
    chunks = lapply(file_names, readRDS)
    x = do.call(rbind, chunks)
    expression(y = x[, "y"], y2 = 2 * y)
    fname = paste0(as.character(quote("y2")), "_", workerID, ".rds")
    saveRDS("y2", file = fname)
})
expression(2 * 3)
