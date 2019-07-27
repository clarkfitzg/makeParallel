#' Single sequential forks scheduler
#'
#' @export
#' @inheritParams scheduleTaskList
#' @param overhead seconds required to initialize a fork
#' @return schedule \linkS4class{ForkSchedule}
scheduleFork = function(graph, platform = Platform(), data = list()
    , overhead = 1e-3
    , bandwidth = 1.5e9
){
    sequence = scheduleForkSeq(graph, overhead)

    evaluation = sequenceToFork(sequence, graph@time, overhead)
 
    ForkSchedule(graph = graph
                 , evaluation = evaluation
                 , sequence = sequence
                 , overhead = overhead
                 , transfer = data.frame() # TODO: actually put these in
                 , nWorkers = max(evaluation[, "processor"])
                 , bandwidth = bandwidth
                 )
}


# - start_time
# - end_time
# - processor
# - node (optional)
# - label (optional)
sequenceToFork = function(sequence, exprTimes, overhead)
{
    n = length(sequence)
    start_time = end_time = processor = node = rep(NA, n)

    cases = forkJoinRun(sequence)

    time = 0
    for(i in seq(n)){
        node_i = sequence[i]
        node[i] = node_i
        switch(cases[i]
            , run = {
                start_time[i] = time
                time = time + exprTimes[node_i]
                end_time[i] = time
                processor[i] = 1L
            }
            , fork = {
                time = time + overhead
                start_time[i] = time
                end_time_i = time + exprTimes[node_i]
                end_time[i] = end_time_i
                processor[i] = lowestAvailable(start_time, end_time
                    , start_time_i = time, end_time_i = end_time_i
                    , processor = processor)
            }
            , join = {
                # Rely on this running in sequence, so the fork is already
                # there. No need to do any updates because the join rows
                # will be dropped.
                fork_done_time = end_time[node == node_i & !is.na(end_time)]
                time = max(time, fork_done_time)
            }
        )
    }

    out = data.frame(start_time, end_time, processor, node)
    out[cases != "join", ]
}


# What is the lowest available processor?
lowestAvailable = function(start_time, end_time, start_time_i, end_time_i, processor)
{
    candidate = 2L
    while(!available(candidate, start_time, end_time, start_time_i, end_time_i, processor))
        candidate = candidate + 1L
    candidate
}


# Is candidate available to be assigned between start_time_i and
# end_time_i?
available = function(candidate, start_time, end_time, start_time_i, end_time_i, processor)
{
    same_proc = processor == candidate & !is.na(processor)
    if(!any(same_proc)){
        # Nothing assigned on this processor yet
        return(TRUE)
    }
    start = start_time[same_proc]
    end = end_time[same_proc]
    ol = mapply(overlap, start, end, start_time_i, end_time_i)
    !any(ol)
}


# Do the intervals [left1, right1] and [left2, right2] overlap?
overlap = function(left1, right1, left2, right2)
{
    right2 < left1 || right1 < left2
}


# @return schedule integer representing the schedule. If an index appears
# twice, then the first appearance is the fork, and the second is the
# join. Indices appearing once mean don't fork.
scheduleForkSeq = function(graph
    , overhead
){
    nnodes = length(graph@code)
    graphdf = graph@graph
    times = time(graph)

    # Remove elements from this vector at each iteration.
    # When it's empty we stop.
    might_fork = seq(nnodes)
    might_fork = might_fork[times > overhead]

    cur_schedule = seq(nnodes)

    # I imagine this pattern generalizes to other greedy algorithms.
    # But I'm not going to generalize it now.
    for(i in seq_along(might_fork)){
        forks = lapply(might_fork, forkOne
                       , schedule = cur_schedule, graphdf = graphdf
                       , times = times, overhead = overhead)

        # Remove forked nodes that slow down the program.
        reduction = sapply(forks, `[[`, "reduction")
        slowdowns = reduction < 0
        might_fork = setdiff(might_fork, might_fork[slowdowns])
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
    blocks = forkSplit(node, schedule)

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
         , reduction = time_node + time_ind - max(time_node, time_ind) - overhead
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


# Either a fork, join, or run
forkJoinRun = function(schedule)
{
    out = rep("run", length(schedule))
    fj = forkJoinLocation(schedule)
    forkNodes = unique(schedule[fj])
    for(node in forkNodes){
        locs = which(schedule == forkNodes)
        # There can only be two locations,
        # and forks always precede the join.
        out[locs[1]] = "fork"
        out[locs[2]] = "join"
    }
    out
}


# Split the schedule vector based on the locations of the forks.
# Each node is located in a block between fork statements, or the program
# start or end.
forkSplit = function(node, schedule)
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
         , after = after[after != sentinel]
         )
}


# Partition nodegroup into ancestors, descendants, and independent with
# respect to node. Returning the groups in sorted order guarantees a valid
# topological order with respect to the graph.
# This is a more general function than forkSplit
partition = function(node, nodegroup, graph)
{
    out = list(ancestors = familyTree(node, "ancestors", nodegroup, graph)
            , descendants = familyTree(node, "descendants", nodegroup, graph)
            )
    related = do.call(c, out)
    out[["independent"]] = setdiff(nodegroup, c(node, related))
    lapply(out, sort)
}


# Recursively compute part of a family tree and intersect with nodegroup
familyTree = function(node, direction, nodegroup, graph)
{
    onegen = switch(direction, ancestors = predecessors, descendants = successors)
    g1 = onegen(node, graph)
    g1 = intersect(g1, nodegroup)
    g2plus = lapply(g1, familyTree, direction = direction
                     , nodegroup = nodegroup, graph = graph)
    as.integer(unique(c(g1, unlist(g2plus))))
}
