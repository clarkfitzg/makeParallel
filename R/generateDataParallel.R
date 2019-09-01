#' @export
setMethod("generate", signature(schedule = "DataParallelSchedule", platform = "ParallelLocalCluster", data = "ANY"),
function(schedule, platform, data, ...)
{
# Idea:
# We can generate all the code independently for each block, and then just stick it all together to make the complete program.
# Assuming it's all R code, of course.

    # localInitBlock could be a method, and this would work more generally.
    # Or we could dispatch generate on an InitBlock object, but then we'd have to do some contortions to avoid infinite recursion.
    initBlock = localInitBlock(schedule, platform)
    newcode = lapply(schedule@blocks, generate, platform = platform, data = data, ...)
    newcode = do.call(c, newcode)
    GeneratedCode(schedule = schedule, code = c(initBlock, newcode))
})


# The following methods for the platform = "ParallelLocalCluster" are designed to work together.
# I'm not thinking about name collisions at all right now.

localInitBlock = function(schedule, platform
         , message = sprintf("This code was generated from R by makeParallel version %s at %s", packageVersion("makeParallel"), Sys.time())
         , template = parse(text = '
message(`_MESSAGE`)

library(parallel)

assignments = `_ASSIGNMENT_INDICES`
nWorkers = `_NWORKERS`

`_CLUSTER_NAME` = makeCluster(nWorkers)

# TODO: This is a hack until proper combining functions work:
c.data.frame = rbind
# It will break code that tries to use the list method for c() on a data.frame

clusterExport(`_CLUSTER_NAME`, c("assignments", "c.data.frame"))
parLapply(cls, seq(nWorkers), function(i) assign("workerID", i, globalenv()))

clusterEvalQ(`_CLUSTER_NAME`, {
    assignments = which(assignments == workerID)
    NULL
})
'), ...){
    substitute_language(template, list(`_MESSAGE` = message
        , `_NWORKERS` = schedule@nWorkers
        , `_ASSIGNMENT_INDICES` = schedule@assignmentIndices
        , `_CLUSTER_NAME` = as.symbol(platform@name)
        ))
}


setMethod("generate", signature(schedule = "DataLoadBlock", platform = "ParallelLocalCluster", data = "ChunkDataFiles"),
function(schedule, platform, data
         , combine_func = as.symbol("c") # TODO: Use rbind if it's a data.frame
         , template = parse(text = '
clusterEvalQ(`_CLUSTER_NAME`, {
    read_args = `_READ_ARGS`
    read_args = read_args[assignments]
    chunks = lapply(read_args, `_READ_FUNC`)
    `_DATA_VARNAME` = do.call(`_COMBINE_FUNC`, chunks)
    NULL
})
'), ...){
    substitute_language(template, list(`_CLUSTER_NAME` = as.symbol(platform@name)
        , `_READ_ARGS` = data@files
        , `_READ_FUNC` = data@readFuncName 
        , `_DATA_VARNAME` = data@varName
        , `_COMBINE_FUNC` = combine_func
        ))
})


setMethod("generate", signature(schedule = "SerialBlock", platform = "ParallelLocalCluster", data = "ANY"),
function(schedule, platform, data
         , combine_func = as.symbol("c") # TODO: Use rbind if it's a data.frame
         , template = parse(text = '
collected = clusterEvalQ(`_CLUSTER_NAME`, {
    `_OBJECTS_RECEIVE_FROM_WORKERS`
})

# Unpack and assemble the objects
vars_to_collect = names(collected[[1]])
for(i in seq_along(vars_to_collect)){
    varname = vars_to_collect[i]
    chunks = lapply(collected, `[[`, i)
    value = do.call(`_COMBINE_FUNC`, chunks)
    assign(varname, value)
}
'), ...){
    if(1 <= length(schedule@collect)){
        first = substitute_language(template, list(`_CLUSTER_NAME` = as.symbol(platform@name)
            , `_OBJECTS_RECEIVE_FROM_WORKERS` = char_to_symbol_list(schedule@collect)
            , `_COMBINE_FUNC` = combine_func
            ))
    } else {
        first = expression()
    }
    c(first, schedule@code)
})


setMethod("generate", signature(schedule = "ParallelBlock", platform = "ParallelLocalCluster", data = "ANY"),
function(schedule, platform
         , export_template = parse(text = '
clusterExport(`_CLUSTER_NAME`, `_EXPORT`)
')
         , run_template = parse(text = '
clusterEvalQ(`_CLUSTER_NAME`, {
    `_BODY`
    NULL
})
'), ...){
    
    part1 = if(0 == length(schedule@export)){
        expression()
    } else {
        substitute_language(export_template, list(
            `_CLUSTER_NAME` = as.symbol(platform@name)
            , `_EXPORT` = schedule@export
            ))
    }

    part2 = substitute_language(run_template, list(`_CLUSTER_NAME` = as.symbol(platform@name)
        , `_BODY` = schedule@code
        ))

    c(part1, part2)
})


setMethod("generate", signature(schedule = "GroupByBlock", platform = "ParallelLocalCluster", data = "ANY"),
function(schedule, platform
         , template = parse(text = '
clusterEvalQ(`_CLUSTER_NAME`, {
    NULL
})
'), ...){
.NotYetImplemented()
    substitute_language(template, list(`_CLUSTER_NAME` = as.symbol(platform@name)
        ))
})


# template = parse(system.file("templates/vector.R", package = "makeParallel")), 
#    data = schedule@data
#
#    if(!is(data, "ChunkDataFiles"))
#        # I could generalize this template with S4 methods, something like the following:
#        # `_READ_ARGS` = chunkLoadArgs(data)
#        # But I'll wait until I have a reason to.
#        stop("Currently only implemented for data of class ChunkDataFiles.")
#
#    code = schedule@graph@code
#    v = schedule@vectorIndices
#
#    newcode = substitute_language(template, list(
#        `_MESSAGE` = sprintf("This code was generated from R by makeParallel version %s at %s", packageVersion("makeParallel"), Sys.time())
#        , `_NWORKERS` = schedule@nWorkers
#        , `_ASSIGNMENT_INDICES` = schedule@assignmentIndices
#        , `_READ_ARGS` = data@files
#        , `_READ_FUNC` = as.symbol(data@readFuncName)
#        , `_DATA_VARNAME` = as.symbol(data@varName)
#        # TODO: Use rbind if it's a data.frame:
#        , `_COMBINE_FUNC` = as.symbol("c")
#        , `_VECTOR_BODY` = code[v]
#        , `_OBJECTS_RECEIVE_FROM_WORKERS` = char_to_symbol_list(schedule@objectsFromWorkers)
#        , `_REMAINDER` = code[-v]
#    ))
#
