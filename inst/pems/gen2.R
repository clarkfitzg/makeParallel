{
    message("This code was generated from R by makeParallel version 0.2.0 at 2019-09-16 19:11:55")
    library(parallel)
    assignments = 1:2
    nWorkers = 2
    cls = makeCluster(nWorkers)
    c.data.frame = rbind
    clusterExport(cls, c("assignments", "c.data.frame"))
    parLapply(cls, seq(nWorkers), function(i) assign("workerID", i, globalenv()))
    clusterEvalQ(cls, {
        assignments = which(assignments == workerID)
        NULL
    })
}
{
    clusterEvalQ(cls, {
        read_args = c("small_grouped_by_stationID/313368.csv", "small_grouped_by_stationID/313369.csv")
        read_args = read_args[assignments]
        chunks = lapply(read_args, read.csv, col.names = c("timeperiod", "station", "flow1", "occupancy1", "speed1", "flow2", "occupancy2", "speed2", "flow3", "occupancy3", "speed3", "flow4", "occupancy4", "speed4", "flow5", "occupancy5", "speed5", "flow6", "occupancy6", "speed6", "flow7", "occupancy7", "speed7", "flow8", "occupancy8", "speed8"), colClasses = c("character", "integer", "integer", "numeric", "numeric", "integer", "numeric", "numeric", "integer", "numeric", "numeric", "integer", "numeric", 
        "numeric", "integer", "numeric", "numeric", "integer", "numeric", "numeric", "integer", "numeric", "numeric", "integer", "numeric", "numeric"), header = FALSE)
        pems = do.call(c, chunks)
        NULL
    })
}
dyncut = function(x, pts_per_bin = 200, lower = 0, upper = 1, min_bin_width = 0.01) {
    x = x[i = x < upper]
    N = length(x = x)
    max_num_cuts = ceiling(x = upper/min_bin_width)
    eachq = pts_per_bin/N
    possible_cuts = quantile(x = x, probs = seq(from = 0, to = 1, by = eachq))
    cuts = rep(x = NA, max_num_cuts)
    current_cut = lower
    for (i in seq_along(along.with = cuts)) {
        possible_cuts = possible_cuts[i = possible_cuts >= current_cut + min_bin_width]
        if (length(x = possible_cuts) == 0) 
            break
        else {
        }
        current_cut = possible_cuts[i = 1]
        cuts[i] = current_cut
    }
    cuts = cuts[i = !is.na(x = cuts)]
    c(lower, cuts, upper)
}
npbin = function(x) {
    breaks = dyncut(x$occupancy2, pts_per_bin = 200)
    binned = cut(x = x$occupancy2, breaks, right = FALSE)
    groups = split(x = x$flow2, f = binned)
    out = data.frame(station = rep(x = x[i = 1, j = "station"], length(x = groups)), right_end_occ = breaks[i = -1], mean_flow = sapply(X = groups, FUN = mean), sd_flow = sapply(X = groups, FUN = sd), number_observed = sapply(X = groups, FUN = length))
    out
}
cols = c("station", "flow2", "occupancy2")
clusterExport(cls, "cols")
clusterEvalQ(cls, {
    {
        pems = pems[j = cols]
        station = pems[j = "station"]
    }
    NULL
})
{
    clusterEvalQ(cls, {
        groupData = pems
        groupIndex = station
        write_one = function(grp, grp_name) {
            group_dir = file.path(".", "pems", grp_name)
            dir.create(group_dir, recursive = TRUE, showWarnings = FALSE)
            path = file.path(group_dir, workerID)
            saveRDS(grp, file = path)
        }
        s = split(groupData, groupIndex)
        Map(write_one, s, names(s))
        NULL
    })
    group_counts_each_worker = clusterEvalQ(cls, table(station))
    add_table = function(x, y) {
        levels = union(names(x), names(y))
        out = rep(0, length(levels))
        out[levels %in% names(x)] = out[levels %in% names(x)] + x
        out[levels %in% names(y)] = out[levels %in% names(y)] + y
        names(out) = levels
        as.table(out)
    }
    group_counts = Reduce(add_table, group_counts_each_worker, init = table(logical()))
    split_assignments = makeParallel:::greedy_assign(group_counts, 2)
    group_names = names(group_counts)
    split_read_args = file.path(".", "pems", group_names)
    names(split_read_args) = group_names
    read_one_group = function(group_dir) {
        files = list.files(group_dir, full.names = TRUE)
        group_chunks = lapply(files, readRDS)
        group = do.call(c, group_chunks)
    }
    clusterExport(cls, c("split_assignments", "split_read_args", "read_one_group"))
    clusterEvalQ(cls, {
        split_assignments = which(split_assignments == workerID)
        split_read_args = split_read_args[split_assignments]
        "pems2" = lapply(split_read_args, read_one_group)
        NULL
    })
}
clusterExport(cls, "npbin")
clusterEvalQ(cls, {
    results = lapply(X = pems2, FUN = npbin)
    NULL
})
{
    collected = clusterEvalQ(cls, {
        list(results = results)
    })
    vars_to_collect = names(collected[[1]])
    for (i in seq_along(vars_to_collect)) {
        varname = vars_to_collect[i]
        chunks = lapply(collected, `[[`, i)
        value = do.call(c, chunks)
        assign(varname, value)
    }
}
results = do.call(what = rbind, args = results)
write.csv(results, "results.csv")
#stopCluster(cls)
