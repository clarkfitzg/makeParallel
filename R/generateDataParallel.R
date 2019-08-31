#' @export
setMethod("generate", signature(schedule = "DataParallelSchedule", platform = "ANY"),
function(schedule, platform, ...)
{
# Idea:
# We can generate all the code independently for each block, and then just stick it all together to make the complete program.

    initBlock = generate(platform = platform)
    newcode = lapply(schedule@blocks, generate, platform = platform, ...)
    newcode = do.call(c, c(initBlock, newcode))
    GeneratedCode(schedule = schedule, code = newcode)
})


# The following methods for the platform = "ParallelLocalCluster" are designed to work together.
# For example, initializing the platform with InitPlatformBlock will define and export the special variable `_ASSIGNMENT_INDICES`, and the code generator for DataLoadBlock will use this variable.

# I need the assignments from the schedule to generate the initialization code.
# Will I need the schedule anywhere else?

setMethod("generate", signature(schedule = "InitPlatformBlock", platform = "ParallelLocalCluster"),
function(schedule, platform
         , message = sprintf("This code was generated from R by makeParallel version %s at %s", packageVersion("makeParallel"), Sys.time())
         , 

         , template = parse(text = "
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


", ...){
    .NotYetImplemented()
})


setMethod("generate", signature(schedule = "DataLoadBlock ", platform = "ParallelLocalCluster"),
function(schedule, platform, ...)
{
    .NotYetImplemented()
})


setMethod("generate", signature(schedule = "SerialBlock", platform = "ParallelLocalCluster"),
function(schedule, platform, ...)
{
    .NotYetImplemented()
})


setMethod("generate", signature(schedule = "ParallelBlock", platform = "ParallelLocalCluster"),
function(schedule, platform, ...)
{
    .NotYetImplemented()
})


setMethod("generate", signature(schedule = "GroupByBlock", platform = "ParallelLocalCluster"),
function(schedule, platform, ...)
{
    .NotYetImplemented()
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
