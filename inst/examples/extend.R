{
    message("This code was generated from R by makeParallel version 0.2.1 at 2019-10-02 14:56:50")
    {
    }
    library(parallel)
    assignments = 1:2
    nWorkers = 2
    cls = makeCluster(nWorkers)
    c.data.frame = rbind
    clusterExport(cls, character(0))
    clusterExport(cls, c("assignments", "c.data.frame"))
    parLapply(cls, seq(nWorkers), function(i) assign("workerID", i, globalenv()))
    clusterEvalQ(cls, {
        assignments = which(assignments == workerID)
        NULL
    })
}
{
    clusterEvalQ(cls, {
        read_args = c("d1.csv", "d2.csv")
        read_args = read_args[assignments]
        chunks = lapply(read_args, function(fname) {
            command = paste("cut -d , -f 2,4", fname)
            read.table(pipe(command), header = FALSE, sep = ",", col.names = c("b", "d"), colClasses = c("numeric", "integer"))
        })
        x = do.call(rbind, chunks)
        NULL
    })
}
{
    collected = clusterEvalQ(cls, {
        list(x = x)
    })
    vars_to_collect = names(collected[[1]])
    for (i in seq_along(vars_to_collect)) {
        varname = vars_to_collect[i]
        chunks = lapply(collected, `[[`, i)
        value = do.call(c, chunks)
        assign(varname, value)
    }
}
b = as.Date(x[, "b"], origin = "2010-01-01")
d = as.Date(x[, "d"], origin = "2010-01-01")
rb = range(b)
rd = range(d)
print(rb)
print(rd)
stopCluster(cls)
