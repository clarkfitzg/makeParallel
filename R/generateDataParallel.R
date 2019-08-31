#' @export
setMethod("generate", signature(schedule = "DataParallelSchedule", platform = "ParallelLocalCluster"),
function(schedule, platform, ...)
{
# Idea:
# We can generate all the code independently for each block, and then just stick it all together to make the complete program.
# Assuming it's all R code, of course.

    initBlock = localInitBlock(schedule, platform)
    newcode = lapply(schedule@blocks, generate, platform = platform, ...)
    newcode = do.call(c, c(initBlock, newcode))
    GeneratedCode(schedule = schedule, code = newcode)
})


# The following methods for the platform = "ParallelLocalCluster" are designed to work together.
# I'm not thinking about name collisions at all right now.

localInitBlock = function(schedule, platform
         , message = sprintf("This code was generated from R by makeParallel version %s at %s", packageVersion("makeParallel"), Sys.time())
         , template = parse(text = '
message(`_MESSAGE`)

library(parallel)

assignments = `_ASSIGNMENT_INDICES`

cls = makeCluster(`_NWORKERS`)

clusterExport(cls, "assignments")
parLapply(cls, seq(nworkers), function(i) assign("workerID", i, globalenv()))

clusterEvalQ(cls, {
    assignments = which(assignments == workerID)
    NULL
})
', ...){
    substitute_language(template, list(`_MESSAGE` = message
        , `_NWORKERS` = schedule@nWorkers
        , `_ASSIGNMENT_INDICES` = schedule@assignmentIndices
        ))
})


setMethod("generate", signature(schedule = "DataLoadBlock ", platform = "ParallelLocalCluster"),
function(schedule, platform
         , template = parse(text = '
clusterEvalQ(cls, {
    NULL
})
', ...){
    substitute_language(template, list(
        ))
})


setMethod("generate", signature(schedule = "SerialBlock", platform = "ParallelLocalCluster"),
function(schedule, platform
         , template = parse(text = '
', ...){
    substitute_language(template, list(
        ))
})


setMethod("generate", signature(schedule = "ParallelBlock", platform = "ParallelLocalCluster"),
function(schedule, platform
         , template = parse(text = '
clusterEvalQ(cls, {
    NULL
})
', ...){
    substitute_language(template, list(
        ))
})


setMethod("generate", signature(schedule = "GroupByBlock", platform = "ParallelLocalCluster"),
function(schedule, platform
         , template = parse(text = '
clusterEvalQ(cls, {
    NULL
})
', ...){
    substitute_language(template, list(
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
