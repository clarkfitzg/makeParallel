{
    message("This code was generated from R by makeParallel version 0.2.0 at 2019-09-15 15:58:17")
    library(parallel)
    assignments = c(1, 2, 1, 2)
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
        read_args = c("/Users/clark/data/pems/d04_text_station_raw_2016_08_22.txt.gz", "/Users/clark/data/pems/d04_text_station_raw_2016_08_23.txt.gz", "/Users/clark/data/pems/d04_text_station_raw_2016_08_24.txt.gz", "/Users/clark/data/pems/d04_text_station_raw_2016_08_25.txt.gz")
        read_args = read_args[assignments]
        chunks = lapply(read_args, read.csv)
        x = do.call(c, chunks)
        NULL
    })
}
dyncut = function(x, pts_per_bin = 200, lower = 0, upper = 1, min_bin_width = 0.01) {
    x = x[x < upper]
    N = length(x)
    max_num_cuts = ceiling(upper/min_bin_width)
    eachq = pts_per_bin/N
    possible_cuts = quantile(x, probs = seq(from = 0, to = 1, by = eachq))
    cuts = rep(NA, max_num_cuts)
    current_cut = lower
    for (i in seq_along(cuts)) {
        possible_cuts = possible_cuts[possible_cuts >= current_cut + min_bin_width]
        if (length(possible_cuts) == 0) 
            break
        else {
        }
        current_cut = possible_cuts[1]
        cuts[i] = current_cut
    }
    cuts = cuts[!is.na(cuts)]
    c(lower, cuts, upper)
}
npbin = function(x) {
    breaks = dyncut(x$occupancy2, pts_per_bin = 200)
    binned = cut(x$occupancy2, breaks, right = FALSE)
    groups = split(x$flow2, binned)
    out = data.frame(station = rep(x[1, "station"], length(groups)), right_end_occ = breaks[-1], mean_flow = sapply(groups, mean), sd_flow = sapply(groups, sd), number_observed = sapply(groups, length))
    out
}
cols = c("station", "flow2", "occupancy2")
pems = pems[, cols]
station = pems[, "station"]
pems2 = split(pems, station)
results = lapply(pems2, npbin)
results = do.call(rbind, results)
write.csv(results, "results.csv")
stopCluster(cls)
