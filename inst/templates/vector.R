#!/usr/bin/env Rscript
# Using nonsyntactic names with backticks should avoid most name collisions.
# To be really safe we could test for name collisions, and then modify them, but I'll wait until it becomes an issue.

message(`_MESSAGE`)

library(parallel)

nworkers = `_NWORKERS`
assignments = `_ASSIGNMENT_INDICES`
read_args = `_READ_ARGS`

cls = makeCluster(nworkers)

clusterExport(cls, c("assignments", "read_args"))
parLapply(cls, seq(nworkers), function(i) assign("workerID", i, globalenv()))

collected = clusterEvalQ(cls, {
    read_args = read_args[assignments[[workerID]]]
    chunks = lapply(read_args, `_READ_FUNC`)
    `_DATA_VARNAME` = do.call(`_COMBINE_FUNC`, chunks)

    `_VECTOR_BODY`

    `_OBJECTS_RECEIVE_FROM_WORKERS`
})

# Unpack and assemble these objects
# TODO:

`_REMAINDER`
