# Thu Feb 23 09:56:02 PST 2017

#' Create a single edge from the most recent output less than i, to i
one_edge = function(i, output)
{
    if(i == output[1]){
        # Don't count the first one
        return(integer())
    }
    src = tail(output[i > output], 1)
    c(src, i)
}


#' Where does x show up in locs
#' 
#' @param x character
#' @param locs list of character vectors
where_index = function(x, locs)
{
    which(sapply(locs, function(locs_i) x %in% locs_i))
}


#' Use Definition Chain
#' 
#' A vector of edges from the expression which defines a variable to the
#' expressions that use that variable.
#' 
#' @param varname variable name
#' @param all_uses list containing variable names uses in each expression
#' @param all_definitions list containing variable names defined in each expression
#' @return vector suitable for use with \code{\link[igraph]{make_graph}}.
use_def = function(varname, all_uses, all_definitions)
{
    uses = where_index(varname, all_uses)
    definitions = where_index(varname, all_definitions)

    n = length(uses)

    edges = integer()

    # No edges
    if(n <= 1){
        return(edges)
    }

    # Build edges up iteratively
    # This could be more efficient. Fix when it becomes a problem.
    for(i in uses){
        edges = c(edges, one_edge(i, output))
    }

    edges
}


#' Shuffle vectors x and y together, ie. (x[1], y[1], x[2], y[2], ...)
shuffle = function(x, y)
{
    as.vector(rbind(x, y))
}


#' Add Source Node To Graph
#'
#' Add a source node with index 0 for each node without parents, return resulting graph.
add_source_node = function(g)
{
    incoming = as_adj_list(g, "in")
    noparents = which(sapply(incoming, function(x) length(x) == 0))
    edges = shuffle(1, noparents)
    add_edges(g, edges)
}


#' Expression Dependency Graph
#'
#' Create a DAG representing a set of expression dependencies.
#' I'm not yet trying to take the minimal set of such dependencies, because
#' it's not clear that this is necessary.
#'
#' @param script as returned from \code{\link[CodeDepends]{readScript}}
#' @export
expr_graph = function(script, add_source = FALSE)
{

    # A list of ScriptNodeInfo objects. May be useful to do more with
    # these later, so might want to save or return this object.
    #info = lapply(script, function(x){
        #getInputs(x, collector = inputCollector(checkLibrarySymbols = TRUE))
        #getInputs(x, collector = inputCollector(checkLibrarySymbols = FALSE))
    #})

    info = lapply(script, getInputs)

    n = length(info)

    # Degenerate cases
    if (n == 0){
        return(make_empty_graph())
    }
    if (n == 1){
        # Graph with one node, no edges.
        return(igraph::make_graph(numeric(), n = 1))
    }

    inputs = lapply(info, slot, "inputs")
    outputs = lapply(info, slot, "outputs")
    updates = lapply(info, slot, "updates")
    # Why is @functions use a named vector? And why is value NA?
    functions = lapply(info, function(x) names(x@functions))

    definitions = mapply(c, outputs, updates, SIMPLIFY = FALSE)
    uses = mapply(c, inputs, outputs, updates, functions, SIMPLIFY = FALSE)

    vars = unique(unlist(outputs))
    edges = lapply(vars, use_def, uses, definitions)

    #badones = (sapply(edges, length) %% 2) == 1

    ## TODO: This must be odd. Haven't figured out yet why it's failing
    #if(any(badones)){
    #    warning("Something broke in dependgraph(), threw out:", sum(badones))
    #    edges[badones] = NULL
    #}

    edges = unlist(edges)

    if(add_source){
        g = igraph::make_graph(edges + 1, n = n + 1)
        g = add_source_node(g)
    } else {
        g = igraph::make_graph(edges, n = n)
    }

    # Removes multiple edges
    igraph::simplify(g)
}


#' Count Number Of Nodes In Longest Path For DAG
longest_path = function(dag)
{

    longest = rep(NA, length(V(dag)))

    # Assume that it's topologically sorted
    visitor = function(graph, data, extra) NULL

    bfs(dag, 0, neimode = "out", callback = visitor)

}
