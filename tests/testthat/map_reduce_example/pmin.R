message("This code was generated from R by makeParallel version 0.2.0 at 2019-08-31 11:33:16")
library(parallel)
assignments = c(1, 2, 1)
nWorkers = 2
cls = makeCluster(nWorkers)
clusterExport(cls, "assignments")
parLapply(cls, seq(nWorkers), function(i) assign("workerID", i, globalenv()))
clusterEvalQ(cls, {
    assignments = which(assignments == workerID)
    NULL
})
clusterEvalQ(cls, {
    read_args = c("small1.rds", "big.rds", "small2.rds")
    read_args = read_args[assignments]
    chunks = lapply(read_args, "readRDS")
    "x" = do.call(c, chunks)
    NULL
})
clusterEvalQ(cls, {
    y = sin(x)
    NULL
})
collected = clusterEvalQ(cls, {
    list(y = y)
})
vars_to_collect = names(collected[[1]])
for (i in seq_along(vars_to_collect)) {
    varname = vars_to_collect[i]
    chunks = lapply(collected, `[[`, i)
    value = do.call(c, chunks)
    assign(varname, value)
}
result = min(y)
saveRDS(result, "result.rds")
