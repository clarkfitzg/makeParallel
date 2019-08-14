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
    assignments = which(assignments == workerID)
    read_args = read_args[assignments]
    chunks = lapply(read_args, `_READ_FUNC`)
    # TODO: Generalize this to other combining functions besides c, rbind for data.frame
    # For this we need to know if value is a data.frame
    `_DATA_VARNAME` = do.call(`_COMBINE_FUNC`, chunks)

    `_VECTOR_BODY`

    `_OBJECTS_RECEIVE_FROM_WORKERS`
})

# Unpack and assemble the objects
vars_to_collect = names(collected[[1]])
for(i in seq_along(vars_to_collect)){
    varname = vars_to_collect[i]
    chunks = lapply(collected, `[[`, i)
    # TODO: This assumes the same _COMBINE_FUNC will work, which is not necessarily true.
    value = do.call(`_COMBINE_FUNC`, chunks)
    assign(varname, value)
}


`_REMAINDER`
