# Thu Jun 20 11:37:30 PDT 2019
# I can get this working incrementally by starting with the simplest things possible.
# The simplest thing is a completely chunkable program.

# I plan to add the following features to the software:
#
# 1. GROUP BY pattern detection in code and field in the data description
# 1. column selection at source, using the 'pipe cut' trick
# 2. force a 'collect', say with median
# 3. 'reduce' functions, as in the z score example. 
# 4. Multiple chunkable blocks, where we keep the data loaded on each worker, and return to it.




#' @export
setMethod("inferGraph", signature(code = "Brace", time = "missing"),
    function(code, time, ...){
        expr = lapply(code$contents, as_language)
        expr = as.expression(expr)
        callGeneric(expr, ...)
})


# Recursively find descendants of a node.
# gdf should be a dag or this will recurse infinitely.
descendants = function(node, gdf)
{
    children = gdf$to[gdf$from == node]
    cplus = lapply(children, descendants, gdf = gdf)
    cplus = do.call(c, cplus)
    unique(c(children, cplus))
}


# Find the largest connected set of vector blocks possible
findBigVectorBlock = function(gdf, chunk_obj)
{
    not_chunked = which(!chunk_obj)

    # Drop nodes that are descendants of non chunked nodes.
    has_non_chunked_ancestor = lapply(not_chunked, descendants, gdf = gdf)
    has_non_chunked_ancestor = do.call(c, has_non_chunked_ancestor)
    exclude = c(not_chunked, has_non_chunked_ancestor)

    gdf_vector = gdf[!(gdf$from %in% exclude), ]

    if(nrow(gdf_vector) == 0)
        stop("Cannot find a block of chunkable statements.")

    d0 = min(gdf_vector$from)
    # Picking the smallest index is arbitrary, since there could be several chunkable blocks, and we would like to get all of them, at least all of them that depend on the initial data.
    # One way to do that is to add a node to the dependency graph for the initial load of the large data object, and gather all of its descendants.
    # Even more sophisticated is to "revisit" the data- that doesn't happen yet.
    # This implementation will get only _one_ vector block connected in the use-def graph.

    d = descendants(d0, gdf_vector)
    out = as.integer(c(d0, d))
    setdiff(out, exclude)
}


# Before non chunkable code can run on the manager, all the necessary variables must be present.
# This function finds those variables.
#
# I should be able to pick these objects out of the task graph.
# Otherwise, I'm not really using the graph that I computed.
#
# I can probably hack around this for now, assuming that the vector block happens before the collects.
# Here's the idea:
#   If the vector block happens before the collects, then we can get all outputs and updates from the code in the vector block.
# Then we can get all the inputs to the non vector block.
# We take the intersection of all these names and collect them back onto the manager.
# It's not necessary to also take the chunked objects, because everything from the vector block will be a chunked object.
find_objectsFromWorkers = function(code, vectorIndices)
{
    vector_block = CodeDepends::getInputs(code[vectorIndices])
    non_vector_block = CodeDepends::getInputs(code[-vectorIndices])

    defined = unique(vector_block@outputs, vector_block@updates)
    used = non_vector_block@inputs

    intersect(defined, used)
}


# For the schedule, we just insert the vector block into something like an lapply, and the remaining program happens on the master.
# We'll also need to insert the data loading calls before anything happens, and the saving call after.
# We should be able to keep these independent of the actual program.




# Standard greedy algorithm for assigning tasks of varied length to homogeneous workers such that we try to minimize the time that the last task is finished.
greedy_assign = function(tasktimes, w)
{
    workertimes = rep(0, w)
    assignments = rep(NA, length(tasktimes))
    for(idx in seq_along(tasktimes)){
        worker = which.min(workertimes)
        workertimes[worker] = workertimes[worker] + tasktimes[idx]
        assignments[idx] = worker
    }
    assignments
}


# Find the names of all variables that need to move between the worker and the manager, either way, and return a character vector of their names.
# Assumes everything chunked is a symbol, which holds if the code has been "expanded" into simple form.
# Assumes that the names in resources are correct, which holds if we've used SSA.
findVarsToMove = function(node, resources, predicate = isChunked)
{
    matches = rstatic::find_nodes(node, predicate, resources)
    out = sapply(matches, function(idx) node[[idx]]$ssa_name)

    if(length(out) == 0)
        # No chunked variables in this node.
        return(character())

    if(!is.character(out))
        stop("Current implementation cannot handle this case. Maybe subexpressions are the problem?")
    out
}


# This is the naive approach of iterating through each top level expression and turning each one into a CodeBlock.
# Below is the current state.
#
# What it does:
#   - export non chunked objects from the manager to the workers
#
# What it does not do yet:
#   - handle subexpressions that are chunked
#   - track which variables have been collected, and avoid collecting them multiple times.
#   - combine blocks (although it's not difficult to combine adjacent ones)
#   - rearrange statements
#   - try to save memory by garbage collecting
nodeToCodeBlock = function(node, resources)
{
    code = as.expression(rstatic::as_language(node))

    r = get_resource(node, resources)
    
    if(!is.null(r$split) && r$split){
        # x, f are argument names in split:
        x_nm = resources[[r[["IDsplit_x"]]]]$varName
        f_nm = resources[[r[["IDsplit_f"]]]]$varName

        return(SplitBlock(code = code, groupData = x_nm, groupIndex = f_nm))
    }

    if(isChunked(node, resources)){
        export = findVarsToMove(node, resources, predicate = isLocalNotChunked)
        ParallelBlock(code = code, export = export)
    } else {
        collect = findVarsToMove(node, resources)
        SerialBlock(code = code, collect = collect)
    }
}


#' Schedule Based On Data Parallelism
#'
#' If you're doing a series of computations over a large data set, then start with this scheduler.
#' This scheduler combines as many chunkable expressions as it can into large blocks of chunkable expressions to run in parallel.
#' The initial data chunks and intermediate objects stay on the workers and do not return to the manager, so you can think of it as "chunk fusion".
#'
#' It statically balances the load of the data chunks among workers, assuming that loading and processing times are linear in the size of the data.
#'
#' TODO:
#'
#' 1. Populate `chunkableFuncs` based on code analysis.
#' 1. Model non chunkable functions so that we can revisit the chunked data.
#'      Currently it only allows for one chunked block.
#' 2. Identify which parameters a function is chunkable in, and respect these by matching arguments.
#'      See `update_resource.Call`.
#' 3. Clarify behavior of subexpressions, handling cases such as `min(sin(large_object))`
#'
#' @inheritParams schedule
#' @param knownChunkableFuncs character, the names of chunkable functions from recommended and base packages.
#' @param chunkableFuncs character, names of additional chunkable functions known to the user.
#' @param allChunkableFuncs character, names of all chunkable functions to use in the analysis.
#' @seealso [makeParallel], [schedule]
#' @export
#' @md
scheduleDataParallel = function(graph, platform = Platform(), data
    , nWorkers = platform@nWorkers
    , KnownChunkableFuncs = c("exp", "+", "*", "sin")
    , chunkableFuncs = character()
    , allChunkableFuncs = c(KnownChunkableFuncs, chunkableFuncs)
    )
{
    if(!is(data, "ChunkDataFiles")) 
        stop("Currently only implemented for ChunkDataFiles.")

    nchunks = length(data@files)

    assignmentIndices = greedy_assign(data@sizes, nWorkers)

    name_resource = new.env()
    resources = new.env()
    namer = namer_factory()

    data_id = namer()
    name_resource[[data@varName]] = data_id
    resources[[data_id]] = list(chunked_object = TRUE, varName = data@varName)

    ast = rstatic::to_ast(graph@code)
    if(!is(ast, "Brace"))
        stop("AST has unexpected form.")

    # Mark everything with whether it's a chunked object or not.
    propagate(ast, name_resource, resources, namer, chunkableFuncs = allChunkableFuncs)

    # It may be better to put the data loading block somewhere else in the schedule, but if we put them first, then the objects are guaranteed to be there when we need them later.
    load_block = DataLoadBlock()
    blocks = lapply(ast$contents, nodeToCodeBlock, resources = resources)
    blocks = c(load_block, blocks)

    DataParallelSchedule(assignmentIndices = assignmentIndices
                       , nWorkers = nWorkers
                       , blocks = blocks
                       )
}


# Turns c("a", "b", "c") into this call:
# list(a = a, b = b, c = c)
char_to_symbol_list = function(vars)
{
    lc = call("list")
    for(v in vars){
        lc[[v]] = as.symbol(v)
    }
    lc
}
