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
    times = time(graph)

    # This algorithm works by continually removing elements from this
    # vector.
    might_fork = seq(nnodes)
    might_fork = might_fork[times > overhead]

    cur_schedule = seq(nnodes)

    # I imagine this pattern generalizes to other greedy algorithms.
    # But I'm not going to generalize it now.
    for(i in seq_len(might_fork)){
        forks = lapply(might_fork, forkOne
                       , schedule = cur_schedule, graphdf = graphdf
                       , times = times, overhead = overhead)

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
# TODO: add join overhead as a function of data transferred.
forkOne = function(node, schedule, graphdf, times, overhead)
{
    blocks = blockSplit(node, schedule)

    p = partition(node, blocks[["hasnode"]], graphdf)

    new_schedule = list(blocks[["before"]]
                        , p[["ancestors"]]
                        , list(node)
                        , p[["independent"]]
                        , list(node)
                        , p[["descendants"]]
                        , blocks[["after"]]
                        )

    time_ind = sum(times[p[["independent"]]])
    time_node = times[node]
    
    list(node = node
         , schedule = unlist(new_schedule)
         , reduction = time_node + time_ind - max(time_node + time_ind) - overhead
         )
}


# Boolean vector identifying forks and joins
forkJoinLocation = function(schedule)
{
    tbl = table(schedule)
    repeats = names(tbl)[tbl == 2]
    repeats = as.integer(repeats)
    schedule %in% repeats
}


# Each node is located in a block between fork statements, or the program
# start or end.
blockSplit = function(node, schedule)
{
    # This function is called repeatedly with the same schedule, so many of
    # these steps will be redundant. I'll come back and optimize it if it
    # becomes an issue.

    # This code is ugly for what it does. I wrote a vectorized version,
    # it's even worse.

    # Represent the end and beginning of the program in the same way as a
    # fork to simplify the logic.
    sentinel = min(schedule) - 1L
    schedule0 = c(sentinel, schedule, sentinel)

    fj = forkJoinLocation(schedule0)

    idx = which(schedule0 == node)

    # Walk left until we find a fork
    leftIndex = idx
    while(!fj[leftIndex] && leftIndex > 1){
        leftIndex = leftIndex - 1
    }

    # Walk right
    n = length(schedule0)
    rightIndex = idx
    while(!fj[rightIndex] && rightIndex < n){
        rightIndex = rightIndex + 1
    }

    before = schedule0[seq(1, leftIndex)]
    after = schedule0[seq(rightIndex, n)]

    # Remove the sentinels before returning.
    list(before = before[before != sentinel]
         , hasnode = schedule0[seq(leftIndex + 1, rightIndex - 1)]
         , after = after[after != sentinel0]
         )
}


# Partition nodegroup into ancestors, descendants, and independent with
# respect to node. Returning the groups in sorted order guarantees a valid
# topological order with respect to the graph.
partition = function(node, nodegroup, graph)
{
    out = list(ancestors = familyTree(node, "ancestors", nodegroup, graph)
            , descendants = familyTree(node, "descendants", nodegroup, graph)
            )
    related = do.call(c, out)
    out[["independent"]] = setdiff(nodegroup, related)
    lapply(out, sort)
}


# Recursively compute part of a family tree and intersect with nodegroup
familyTree = function(node, direction, nodegroup, graph)
{
    onegen = switch(direction, ancestors = predecessors, descendants = successors)
    g1 = onegen(node, graph)
    g1 = intersect(g1, nodegroup)
    g2plus = sapply(g1, familyTree, direction = direction
                     , nodegroup = nodegroup, graph = graph)
    c(g1, g2plus)
}
