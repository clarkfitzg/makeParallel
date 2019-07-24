# Thu Jun 20 11:37:30 PDT 2019
# I can get this working incrementally by starting with the simplest things possible.
# The simplest thing is a completely vectorized program.

# I plan to add the following features to the software in this order:
#
# 1. column selection at source, using the 'pipe cut' trick
# 2. force a 'collect', say with median
# 3. 'reduce' functions, as in the z score example. 
# 4. Multiple vectorized blocks, where we keep the data loaded on each worker, and return to it.


# Developing stuff that should make its way into makeParallel
library(makeParallel)

source("propagate.R")


setOldClass("Brace")


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



ChunkLoadFunc = setClass("ChunkLoadFunc", contains = "DataSource",
         slots = c(read_func = "character", file_names = "character", varname = "character", combine_func = "character"))

VectorSchedule = setClass("VectorSchedule", contains = "Schedule",
         slots = c(assignment_list = "list"
                   , nworkers = "integer"
                   , data = "ChunkLoadFunc"
                   , save_var = "character"
                   , vector_indices = "integer"
                   ))

#
#
#
# @param save_var character, name of the variable to save
scheduleVector = function(graph, data, save_var, nworkers = 2L, vector_funcs = c("exp", "+", "*"), ...)
{
    if(!is(data, "ChunkLoadFunc")) 
        stop("This function is currently only implemented for data of class ChunkLoadFunc.")

    nchunks = length(data@file_names)

    # This is where the logic for splitting the chunks will go.
    # Fall back to even splitting if we don't know how big the chunks are.
    assignments = parallel::splitIndices(nchunks, nworkers)

    name_resource = new.env()
    resources = new.env()
    namer = namer_factory()

    data_id = namer()
    name_resource[[data@varname]] = data_id
    resources[[data_id]] = list(chunked_object = TRUE)

    ast = to_ast(graph@code)

    # Mark everything with whether it's a chunked object or not.
    propagate(ast, name_resource, resources, namer, vector_funcs = vector_funcs)

    chunk_obj = sapply(ast$contents, is_chunked, resources = resources)

    vector_indices = findBigVectorBlock(graph@graph, chunk_obj)

    # TODO: Check that save_var is actually produced in the vector block

    VectorSchedule(graph = graph
                   , assignment_list = assignments
                   , nworkers = as.integer(nworkers)
                   , save_var = save_var
                   , vector_indices = vector_indices
                   , data = data
                   )
}


code_to_char = function(code) paste(as.character(code), collapse = "\n")


setMethod("generate", "VectorSchedule", function(schedule, ...){

    template = readLines("vector_template.R")
    assign_string = deparse(schedule@assignment_list)
    data = schedule@data

    code = schedule@graph@code
    v = schedule@vector_indices
    vector_body = code_to_char(code[v])
    remainder = code_to_char(code[-v])
    fnames = deparse(data@file_names)

    output_code = whisker::whisker.render(template, list(
        gen_time = Sys.time()
        , file_names = fnames
        , nworkers = schedule@nworkers
        , assignment_list = assign_string
        , read_func = data@read_func
        , data_varname = data@varname
        , combine_func = data@combine_func
        , vector_body = vector_body
        , save_var = schedule@save_var
        , remainder = remainder
    ))

    newcode = parse(text = output_code)

    GeneratedCode(schedule = schedule, code = newcode)
})





if(FALSE){
# Code for development
name_resource = new.env()
resources = new.env()
namer = namer_factory()

x_id = namer()
name_resource[["x"]] = x_id
resources[[x_id]] = list(chunked_object = TRUE)

ast = to_ast(quote({
    y = x[, "y"]
    y2 = 2 * y
    2 * 3
}))

# Mark everything with whether it's a chunked object or not.
propagate(ast, name_resource, resources, namer, vector_funcs = c("exp", "+", "*"))

# Should be a chunked object
get_resource(ast[[2]], resources)

g = inferGraph(ast)
gdf = g@graph

bl = findBigVectorBlock(gdf, chunk_obj)

}
