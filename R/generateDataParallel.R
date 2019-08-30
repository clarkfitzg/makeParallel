#' @export
setMethod("generate", "DataParallelSchedule",
function(schedule, platform, ...)
{
# Idea:
# We can generate all the code independently for each block, and then just stick it all together to make the complete program.

    # TODO: Initialize, data loading code

    firstBlock = 
    newcode = lapply(schedule@blocks, generateBlock, platform = platform, ...)
    newcode = do.call(c, c(firstBlock, newcode))
    new
    GeneratedCode(schedule = schedule, code = newcode)
})


generateFirstBlock = 


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
