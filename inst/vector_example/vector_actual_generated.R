library(parallel)
nworkers = 2
assignments = list(1:2, 3:4)
file_names = c("x1.rds", "x2.rds", "x3.rds", "x4.rds")
cls = makeCluster(nworkers)
clusterExport(cls, c("assignments", "file_names"))
parLapply(cls, seq(nworkers), function(i) assign("workerID", i, globalenv()))
clusterEvalQ(cls, {
    file_names = file_names[assignments[[workerID]]]
    chunks = lapply(file_names, readRDS)
    x = do.call(rbind, chunks)
    y = x[, "y"]
    y2 = 2 * y
    saveRDS(y2, file = paste0("y2_", workerID, ".rds"))
})
2 * 3
