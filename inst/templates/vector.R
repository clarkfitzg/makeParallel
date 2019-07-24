#!/usr/bin/env Rscript

message(`_MESSAGE`)

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

    fname = paste0(`_SAVE_VAR_NAME`, "_", workerID, ".rds")

    # Could parameterize this saving function
    saveRDS(`_SAVE_VAR`, file = fname)
})

`_REMAINDER`
