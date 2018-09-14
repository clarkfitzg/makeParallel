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


# The main idea is that we would like to fork node as soon as possible and
# join node as late as possible.
forkOne = function(node, schedule, graphdf)
{
    blocks = blocksplit(node, schedule)

    p = partition(node, blocks[["hasnode"]], graphdf)

    new_schedule = list(blocks[["before"]]
                        , p[["ancestors"]]
                        , list(node)
                        , p[["independent"]]
                        , list(node)
                        , p[["descendants"]]
                        , blocks[["after"]]
                        )
    
    list(node = node
         , schedule = unlist(new_schedule)
         , reduction = reduction
         )
}


# Each node is located in a block defined with end
blocksplit = function(node, schedule)
{
    list(before = 
         , hasnode = 
         , after = 
         )
}


# Partition nodegroup into ancestors, descendants, and independent with
# respect to node. Returning the groups in sorted order guarantees a valid
# topological order with respect to the graph.
partition = function(node, nodegroup, graph)
{
    out = list(ancestors = familytree(node, "ancestors", nodegroup, graph)
            , descendants = familytree(node, "descendants", nodegroup, graph)
            )
    related = do.call(c, out)
    out[["independent"]] = setdiff(nodegroup, related)
    lapply(out, sort)
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
