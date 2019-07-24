#!/usr/bin/env Rscript

message(sprintf("This code was generated from R by makeParallel version %s at %s", `_VERSION`, `_GEN_TIME`))

library(parallel)

nworkers = `_NWORKERS`
assignments = `_ASSIGNMENT_LIST`
file_names = `_FILE_NAMES`

cls = makeCluster(nworkers)

clusterExport(cls, c("assignments", "file_names"))
parLapply(cls, seq(nworkers), function(i) assign("workerID", i, globalenv()))

clusterEvalQ(cls, {
    file_names = file_names[assignments[[workerID]]]
    chunks = lapply(file_names, `_READ_FUNC`)
    `_DATA_VARNAME` = do.call(`_COMBINE_FUNC`, chunks)

    `_VECTOR_BODY`

    fname = paste0(as.character(quote(`_SAVE_VAR`)), "_", workerID, ".rds")

    # Could parameterize this saving function
    saveRDS(`_SAVE_VAR`, file = fname)
})

`_REMAINDER`
