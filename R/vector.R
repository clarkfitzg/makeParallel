# Thu Jun 20 11:37:30 PDT 2019
# I can get this working incrementally by starting with the simplest things possible.
# The simplest thing is a completely vectorized program.

# I plan to add the following features to the software:
#
# 1. GROUP BY pattern detection in code and field in the data description
# 1. column selection at source, using the 'pipe cut' trick
# 2. force a 'collect', say with median
# 3. 'reduce' functions, as in the z score example. 
# 4. Multiple vectorized blocks, where we keep the data loaded on each worker, and return to it.




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
# This will only pick up those nodes that are connected through dependencies- we could include siblings as well.
# One way to do that is to have a node for the initial load of the large data object, and gather all of its descendants.
findBigVectorBlock = function(gdf, chunk_obj)
{
    not_chunked = which(!chunk_obj)

    # Drop nodes that are descendants of non chunked nodes.
    d2 = lapply(not_chunked, descendants, gdf = gdf)
    d2 = do.call(c, d2)
    exclude = c(not_chunked, d2)

    # This graph contains only the ones we need
    pruned = gdf[!(gdf$from %in% exclude) & !(gdf$to %in% exclude), ]

    # Picking the smallest index is somewhat arbitrary.
    d0 = min(pruned$from)
    d = descendants(d0, pruned)
    as.integer(c(d0, d))
}



# For the schedule, we just insert the vector block into something like an lapply, and the remaining program happens on the master.
# We'll also need to insert the data loading calls before anything happens, and the saving call after.
# We should be able to keep these independent of the actual program.



#' @export ChunkLoadFunc
#' @exportClass ChunkLoadFunc
#' @slot read_func_name for example, "read.csv".
#'      Using a character means that the function must be available, which in practice probably means it ships with R.
#'      We should generalize this to allow functions from packages and user defined functions.
#' @slot read_args arguments to read the function, probably the names of files.
#'      It could accept a general vector, but I'll need to think more carefully about how to generate code with an object that's not a character.
#'      One way is to serialize the object right into the script.
#'      Another way is to deparse and parse.
ChunkLoadFunc = setClass("ChunkLoadFunc", contains = "DataSource",
         slots = c(read_func_name = "character", read_args = "character", varname = "character", combine_func_name = "character"))


setValidity("ChunkLoadFunc", function(object)
{
    if(length(object@read_args) == 0) "No files specified" 
    else TRUE
})


#' @export
VectorSchedule = setClass("VectorSchedule", contains = "Schedule",
         slots = c(assignment_indices = "list"
                   , nworkers = "integer"
                   , data = "ChunkLoadFunc"
                   , save_var = "character"
                   , vector_indices = "integer"
                   ))


#' @param save_var character, name of the variable to save
#' @export
scheduleVector = function(graph, data, save_var, nWorkers = 2L, vector_funcs = c("exp", "+", "*"), ...)
{
    if(!is(data, "ChunkLoadFunc")) 
        stop("This function is currently only implemented for data of class ChunkLoadFunc.")

    nchunks = length(data@read_args)

    # This is where the logic for splitting the chunks will go.
    # Fall back to even splitting if we don't know how big the chunks are.
    assignments = parallel::splitIndices(nchunks, nworkers)

    name_resource = new.env()
    resources = new.env()
    namer = namer_factory()

    data_id = namer()
    name_resource[[data@varname]] = data_id
    resources[[data_id]] = list(chunked_object = TRUE)

    ast = rstatic::to_ast(graph@code)

    # Mark everything with whether it's a chunked object or not.
    propagate(ast, name_resource, resources, namer, vector_funcs = vector_funcs)

    chunk_obj = sapply(ast$contents, is_chunked, resources = resources)

    vector_indices = findBigVectorBlock(graph@graph, chunk_obj)

    # TODO: Check that save_var is actually produced in the vector block

    VectorSchedule(graph = graph
                   , assignment_indices = assignments
                   , nworkers = as.integer(nworkers)
                   , save_var = save_var
                   , vector_indices = vector_indices
                   , data = data
                   )
}


#' @export
setMethod("generate", "VectorSchedule",
function(schedule, template = parse(system.file("templates/vector.R", package = "makeParallel")), ...)
{
    data = schedule@data

    code = schedule@graph@code
    v = schedule@vector_indices

    newcode = substitute_language(template, list(
        `_MESSAGE` = sprintf("This code was generated from R by makeParallel version %s at %s", packageVersion("makeParallel"), Sys.time())
        , `_NWORKERS` = schedule@nworkers
        , `_ASSIGNMENT_INDICES` = convert_object_to_language(schedule@assignment_indices)
        , `_READ_ARGS` = data@read_args
        , `_READ_FUNC` = as.symbol(data@read_func_name)
        , `_DATA_VARNAME` = as.symbol(data@varname)
        , `_COMBINE_FUNC` = as.symbol(data@combine_func_name)
        , `_VECTOR_BODY` = code[v]
        , `_SAVE_VAR` = as.symbol(schedule@save_var)
        , `_SAVE_VAR_NAME` = schedule@save_var
        , `_REMAINDER` = code[-v]
    ))

    GeneratedCode(schedule = schedule, code = newcode)
})
