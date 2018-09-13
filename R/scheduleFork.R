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
    out = list(ancestors = ancestors(node, allnodes, graph)
            , descendants = descendants(node, allnodes, graph)
            )
    related = do.call(c, out)
    out[["independent"]] = setdiff(allnodes, related)
    out
}


ancestors = function(node, allnodes, graph)
{
}
