empty_edges = data.frame(from = integer(), to = integer()
        , type = integer(), value = integer(), size = numeric())


# Where does x show up in locs
# 
# @param x character
# @param locs list of character vectors
where_index = function(x, locs)
{
    which(sapply(locs, function(locs_i) x %in% locs_i))
}


#' Use Definition Chain
#' 
#' Compute a data frame of edges with one edge connecting each use of the
#' variable x to the most recent definition or update of x.
#' 
#' @param x variable name
#' @param all_uses list containing variable names uses in each expression
#' @param all_definitions list containing variable names defined in each expression
#' @return data frame of edges suitable for use with
#'  \code{\link[igraph]{graph_from_data_frame}}.
use_def = function(x, all_uses, all_definitions)
{
    varname = x
    uses = where_index(varname, all_uses)
    if(length(uses) == 0){
        return(empty_edges)
    }
    defs = c(where_index(varname, all_definitions), Inf)

    edges = data.frame(from = defs[cut(uses, breaks = defs)]
                       , to = uses
                       )
    edges$type = "use-def"
    edges$value = replicate(nrow(edges), list(varname = varname))
    edges
}


# Shuffle vectors x and y together, ie. (x[1], y[1], x[2], y[2], ...)
shuffle = function(x, y)
{
    as.vector(rbind(x, y))
}


# Add Source Node To Graph
#
# Add a source node with index 0 for each node without parents, return resulting graph.
add_source_node = function(g)
{
    incoming = as_adj_list(g, "in")
    noparents = which(sapply(incoming, function(x) length(x) == 0))
    edges = shuffle(1, noparents)
    add_edges(g, edges)
}


#' @export
#' @rdname inferGraph
setMethod("inferGraph", "character", function(code, ...)
{
    #if(length(code) > 1) stop("pass a single R file name or a language object")
    expr = parse(code, keep.source = TRUE)
    callGeneric(expr, ...)
})


#' @export
#' @rdname inferGraph
setMethod("inferGraph", "language", function(code, ...)
{
    expr = as.expression(code)
    callGeneric(expr, ...)
})


#' @export
#' @rdname inferGraph
setMethod("inferGraph", "expression", function(code, ...)
{
    expr = code
    info = lapply(expr, CodeDepends::getInputs)

    # A list of ScriptNodeInfo objects. May be useful to do more with
    # these later, so might want to save or return this object.
    #info = lapply(script, function(x){
        #getInputs(x, collector = inputCollector(checkLibrarySymbols = TRUE))
        #getInputs(x, collector = inputCollector(checkLibrarySymbols = FALSE))
    #})

    n = length(info)

    # Degenerate case
    if (n <= 1){
        tg = empty_edges
    } else {
        inputs = lapply(info, methods::slot, "inputs")
        outputs = lapply(info, methods::slot, "outputs")
        updates = lapply(info, methods::slot, "updates")
        # Why is @functions use a named vector? And why is value NA?
        functions = lapply(info, function(x) names(x@functions))


        definitions = mapply(c, outputs, updates, SIMPLIFY = FALSE)
        uses = mapply(c, inputs, updates, functions, SIMPLIFY = FALSE)

        vars = unique(unlist(outputs))

        use_def_chains = lapply(vars, use_def, uses, definitions)

        tg = do.call(rbind, use_def_chains)
    }

    new("DependGraph", code = expr, graph = tg)
})


# Count Number Of Nodes In Longest Path For DAG
longest_path = function(dag)
{

    longest = rep(NA, length(V(dag)))

    # Assume that it's topologically sorted
    visitor = function(graph, data, extra) NULL

    bfs(dag, 0, neimode = "out", callback = visitor)

}
