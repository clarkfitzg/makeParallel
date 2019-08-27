message("This code was generated from R by makeParallel version 0.2.0 at 2019-08-20 11:29:10")
library(parallel)
nworkers = 2
assignments = c(1, 2, 1)
read_args = c("small1.rds", "big.rds", "small2.rds")
cls = makeCluster(nworkers)
clusterExport(cls, c("assignments", "read_args"))
parLapply(cls, seq(nworkers), function(i) assign("workerID", i, globalenv()))
collected = clusterEvalQ(cls, {
    assignments = which(assignments == workerID)
    read_args = read_args[assignments]
    chunks = lapply(read_args, readRDS)
    x = do.call(c, chunks)
    y = sin(x)
    list(y = y)
})
vars_to_collect = names(collected[[1]])
for (i in seq_along(vars_to_collect)) {
    varname = vars_to_collect[i]
    chunks = lapply(collected, `[[`, i)
    value = do.call(c, chunks)
    assign(varname, value)
}
{
    result = min(y)
    saveRDS(result, "result.rds")
}
