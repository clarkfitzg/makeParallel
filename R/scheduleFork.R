#' Single sequential forks scheduler
#'
#' @export
#' @inheritParams scheduleTaskList
#' @param overhead seconds required to initialize a fork
#' @return schedule \linkS4Class{ForkSchedule}
scheduleFork = function(graph
    , overhead = 1e-3
){

}


forkOne = function(node, nodegroup, graph)
{
    p = partition(node, nodegroup, graph)
    
}


# Partition nodegroup into ancestors, descendants, and independent with
# respect to node
partition = function(node, nodegroup, graph)
{
    out = list(ancestors = familytree(node, "ancestors", nodegroup, graph)
            , descendants = familytree(node, "descendants", nodegroup, graph)
            )
    related = do.call(c, out)
    out[["independent"]] = setdiff(nodegroup, related)
    out
}


# Recursively compute part of a family tree and intersect with nodegroup
familytree = function(node, direction, nodegroup, graph)
{
    onegen = switch(direction, ancestors = predecessors, descendants = successors)
    g1 = onegen(node, graph)
    g1 = intersect(g1, nodegroup)
    g2plus = sapply(g1, familytree, direction = direction
                     , nodegroup = nodegroup, graph = graph)
    c(g1, g2plus)
}



# Unlist should do what I want, this produces 1:8
#l = list(1:3, list(4, list(5, 6)), list(7), 8)
#unlist(l)

