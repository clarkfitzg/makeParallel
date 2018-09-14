#' Single sequential forks scheduler
#'
#' @export
#' @inheritParams scheduleTaskList
#' @param overhead seconds required to initialize a fork
#' @return schedule \linkS4Class{ForkSchedule}
scheduleFork = function(graph
    , overhead = 1e-3
){
    nnodes = length(graph@code)
    graphdf = graph@graph

    # This algorithm works by continually removing elements from this
    # vector.
    might_fork = seq(nnodes)
    might_fork = might_fork[time(graph) > overhead]

    cur_schedule = seq(nnodes)

    # I imagine this pattern generalizes to other greedy algorithms.
    # But I'm not going to generalize it now.
    for(i in seq_len(might_fork)){
        forks = lapply(might_fork, forkOne
                       , schedule = cur_schedule, graphdf = graphdf)

        # Remove forked nodes that slow down the program.
        reduction = sapply(forks, `[[`, "reduction")
        slowdowns = reduction < 0
        might_fork = setdiff(might_fork, mightfork[slowdowns])
        if(length(might_fork) == 0)
            break

        # Greedy aspect- update the current schedule by choosing the node
        # that most reduces program run time.
        bestnode = forks[[which.max(reduction)]]
        cur_schedule = bestnode[["schedule"]]

        # Check if we're finished each time we update might_fork
        might_fork = setdiff(might_fork, bestnode[["node"]])
        if(length(might_fork) == 0)
            break
    }

    cur_schedule
}


forkOne = function(node, schedule, graphdf)
{
    p = partition(node, schedule, graphdf)
    
    list(node = node
         , schedule = new_schedule
         , reduction = reduction
         )
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
