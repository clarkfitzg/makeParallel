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
        expr = lapply(code$contents, rstatic::as_language)
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
    out = lapply(matches, function(idx) node[[idx]]$ssa_name)
    # Remove the NULLs
    out = unique(do.call(c, out))

    if(length(out) == 0)
        # No chunked variables in this node.
        return(character())

    if(!is.character(out))
        stop("Current implementation cannot handle this case. Maybe subexpressions are the problem?")
    out
}


# Check a call for a simple assignment and return the left hand side (variable that is being assigned to) as a string
getLHS = function(node, possibleFuncs)
{
    if(!is(node, "Assign") || !(node$read$fn$ssa_name %in% possibleFuncs))
        stop("expected a call of the form: s = split(x, y)")

    node$write$ssa_name
}


# This is the naive approach of iterating through each top level expression and turning each one into a CodeBlock.
# Below is the current state.
#
# What it does:
#   - export non chunked objects from the manager to the workers
#   - handle subexpressions that are chunked. (Doubtful this is robust)
#
# What it does not do yet:
#   - track which variables have been collected, and avoid collecting them multiple times.
#   - rearrange statements
#   - try to save memory by garbage collecting
nodeToCodeBlock = function(node, resources, reduceFuncs)
{
    # TODO:
    # This function is getting complicated.
    # It might help to rewrite this to use method dispatch.
    # Then again, that could make it even worse.
 
    code = as.expression(rstatic::as_language(node))

    r = get_resource(node, resources)
  
    if(!is.null(r$split) && r$split){
        # x, f are argument names in split:
        x_nm = resources[[r[["IDsplit_x"]]]]$varName
        f_nm = resources[[r[["IDsplit_f"]]]]$varName

        lhs = getLHS(node, "split")

        return(SplitBlock(code = code, groupData = x_nm, groupIndex = f_nm, lhs = lhs))
    }

    if(!is.null(r$reduceFun)){
        lhs = getLHS(node, names(reduceFuncs))
        args = node$read$args$contents
        arg1 = args[[1]]
        if(1 < length(args) || !is(arg1, "Symbol"))
            stop("This code assumes the reducible function call `foo` is of the form `foo(x)`. Other cases not yet implemented.")
        
        rfun = reduceFuncs[[r$reduceFun]]
        if(rfun@predicate(get_resource(arg1, resources))){
            # Predicate function identifies this particular call as reducible or not based on the properties of the argument.
            # If it isn't reducible, then the general case applies.
            return(ReduceBlock(objectToReduce = args[[1]]$ssa_name
                               , resultName = lhs
                               , reduceFun = rfun))
        }
    } 
    
    if(isChunked(node, resources)){
        export = findVarsToMove(node, resources, predicate = isLocalNotChunked)
        return(ParallelBlock(code = code, export = export))
    } 

    collect = findVarsToMove(node, resources)
    SerialBlock(code = code, collect = collect)
}


topLevelFuncAssign = function(node)
{
    is(node, "Assign") && is(node$read, "Function")
}


# Pull out all the user defined functions assigned to variables from the ast, modifying it in place.
# This is a hack to put all the functions into one place, first in the script, so we can export them to the workers.
# It will fail if a function is redefined in a script, or if a function calls an existing package function and then overwrites it later.
# But who does that?
rm_udf_from_ast = function(ast)
{
    func_indices = sapply(ast$contents, topLevelFuncAssign)
    funcs = ast$contents[func_indices]
    code = rstatic::as_language(rstatic::Brace$new(funcs))
    funcNames = lapply(funcs, function(x) x$write$ssa_name)
    # Necessary to keep the class if there are no funcNames.
    funcNames = as.character(funcNames)

    # Pull the functions out of the AST
    ast$contents[func_indices] = NULL

    list(code = as.expression(code), funcNames = funcNames)
}


# This is so the tests and examples work.
# Can build this up comprehensively later.
getKnownChunkFuncs = function() c("exp", "+", "*", "sin", "as.date")


# The simple ones
getKnownReduceFuncs = function()
{
    fnames = c("max", "min", "range")
    out = lapply(fnames, reduceFun)
    names(out) = fnames
    out
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
#' 2. Identify which parameters a function is chunkable in, and respect these by matching arguments.
#'      See `update_resource.Call`.
#' 3. Clarify behavior of subexpressions, handling cases such as `min(sin(large_object))`
#'
#' @inheritParams schedule
#' @param chunkFuncs character, names of additional chunkable functions known to the user.
#' @param reduceFuncs list of ReduceFun objects, these can override the knownReduceFuncs.
#' @param knownChunkFuncs character, the names of chunkable functions from recommended and base packages.
#' @param knownReduceFuncs list of known ReduceFun objects
#' @param allchunkFuncs character, names of all chunkable functions to use in the analysis.
#' @seealso [makeParallel], [schedule]
#' @export
#' @md
scheduleDataParallel = function(graph, platform = Platform(), data
    , nWorkers = platform@nWorkers
    , chunkFuncs = character()
    , reduceFuncs = list()
    , knownReduceFuncs = getKnownReduceFuncs()
    , knownChunkFuncs = getKnownChunkFuncs()
    , allChunkFuncs = c(knownChunkFuncs, chunkFuncs)
    )
{
    if(!is(data, "ChunkDataFiles")) 
        stop("Currently only implemented for ChunkDataFiles.")

    names(knownReduceFuncs) = sapply(knownReduceFuncs, slot, "reduce")
    names(reduceFuncs) = sapply(reduceFuncs, slot, "reduce")
    allReduceFuncs = knownReduceFuncs
    allReduceFuncs[names(reduceFuncs)] = reduceFuncs

    nchunks = length(data@files)

    assignmentIndices = greedy_assign(data@sizes, nWorkers)

    name_resource = new.env()
    resources = new.env()
    namer = namer_factory()

    data_id = namer()
    name_resource[[data@varName]] = data_id

    # TODO: Generalize how we store and propagate relevant parts of the data description to other resources in the program.
    # What I'm doing here suggests defining a class `Resource` such that `DataSource` contains it.
    r0 = list(chunked = TRUE, varName = data@varName, uniqueValueBound = data@uniqueValueBound)
    resources[[data_id]] = r0

    ast = rstatic::to_ast(graph@code)
    if(!is(ast, "Brace"))
        stop("Unexpected form of AST")

    # Run the code inference and store all the results in `resources`
    propagate(ast, name_resource, resources, namer, chunkFuncs = allChunkFuncs, reduceFuncs = names(allReduceFuncs))

    funcs = rm_udf_from_ast(ast)
    init_block = InitBlock(code = funcs[["code"]]
                           , funcNames = funcs[["funcNames"]]
                           , assignmentIndices = assignmentIndices
                           )

    blocks = lapply(ast$contents, nodeToCodeBlock, resources = resources, reduceFuncs = allReduceFuncs)

    # It may be better to put the data loading block somewhere else in the schedule, but if we put them first, then the objects are guaranteed to be there when we need them later.
    blocks = c(init_block, DataLoadBlock(), blocks, FinalBlock())
    blocks = collapseAdjacentBlocks(blocks)

    DataParallelSchedule(nWorkers = nWorkers, blocks = blocks)
}


# Collapses two or more adjacent SerialBlocks into one. 
# Collapses two or more adjacent ParallelBlocks into one. 
# Reordering should happen before this.
# input is list of blocks before collapsing, output is list of blocks after collapsing.
collapseAdjacentBlocks = function(blocks)
{
    out = list()
    lastblock = blocks[[1]]
    for(b in blocks[-1]){
        tmp = collapseTwoBlocks(lastblock, b)
        if(is(tmp, "CodeBlock")){
            lastblock = tmp
        } else {
            out = c(out, tmp[[1]])
            lastblock = tmp[[2]]
        }
    }
    c(out, lastblock)
}


# inputs are two adjacent blocks to collapse
# output is either a collapsed block, or a list of two blocks.
collapseTwoBlocks = function(b1, b2)
{
    # Multiple dispatch DOES NOT work out so well here, because class inheritance SplitBlock extends ParallelBlock, and we don't want it to inherit a method.
    # We could think harder and do something more general if necessary, but this implementation gets us what we're looking for at the moment.
    c1 = class(b1)
    c2 = class(b2)

    if(c1 == "SerialBlock" && c2 == "SerialBlock"){
        SerialBlock(code = c(b1@code, b2@code), collect = c(b1@collect, b2@collect))
    } else if(c1 == "ParallelBlock" && c2 == "ParallelBlock"){
        ParallelBlock(code = c(b1@code, b2@code), export = c(b1@export, b2@export))
    } else {
        list(b1, b2)
    }
}
