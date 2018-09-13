#' Single sequential forks scheduler
#'
#' @export
#' @inheritParams scheduleTaskList
#' @return schedule \linkS4Class{ForkSchedule}
scheduleFork = function(graph
){

}


forkOne = function(node, allnodes, graph)
{
    p = partition(node_to_fork, graph)
}


# Partition allnodes into ancestors, descendants, and independent with
# respect to node
partition = function(node, allnodes, graph)
{
    out = list(ancestors = familytree(node, "ancestors", allnodes, graph)
            , descendants = familytree(node, "descendants", allnodes, graph)
            )
    related = do.call(c, out)
    out[["independent"]] = setdiff(allnodes, related)
    out
}


# Recursively compute part of a family tree and intersect with allnodes
familytree = function(node, direction, allnodes, graph)
{
    onegen = switch(direction, ancestors = predecessors, descendants = successors)
    g1 = onegen(node, graph)
    g1 = intersect(g1, allnodes)
    g2plus = sapply(g1, familytree, direction = direction
                     , allnodes = allnodes, graph = graph)
    c(g1, g2plus)
}
