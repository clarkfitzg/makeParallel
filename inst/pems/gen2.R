{
    message("This code was generated from R by makeParallel version 0.2.0 at 2019-09-18 11:58:11")
    {
        dyncut = function(x, pts_per_bin = 200, lower = 0, upper = 1, min_bin_width = 0.01) {
            x = x[x < upper]
            N = length(x)
            max_num_cuts = ceiling(upper/min_bin_width)
            eachq = pts_per_bin/N
            possible_cuts = quantile(x, probs = seq(from = 0, to = 1, by = eachq), na.rm = TRUE)
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
    }
    library(parallel)
    assignments = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 19, 18, 3, 1, 10, 15, 2, 4, 9, 14, 11, 16, 6, 5, 7, 12, 17, 8, 20, 13, 18, 19, 10, 3, 10, 1, 9, 3, 12, 15, 4, 16, 11, 2, 14, 7, 13, 19, 6, 5, 17, 8, 20, 18, 13, 10, 15, 7, 12, 1, 6, 3, 19, 9, 4, 18, 11, 16, 2, 14, 17, 5, 8, 20, 13, 10, 15, 7, 16, 12, 6, 1, 2, 3, 19, 11, 9, 4, 18, 14, 13, 17, 20, 5, 8, 10, 15, 3, 7, 12, 16, 19, 6, 1, 18, 2, 4, 11, 9, 14, 13, 15, 17, 8, 20, 10, 5, 3, 6, 7, 19, 16, 12, 1, 14, 
    18, 2, 5, 4, 9, 11, 13, 17, 15, 10, 8, 20, 3, 1, 6, 7, 19, 12, 16, 14, 18, 2, 11, 5, 4, 9, 13, 17, 15, 20, 10, 8, 3, 1, 7, 6, 19, 14, 16, 12, 18, 2, 11, 5, 9, 4, 13, 17, 20, 15, 10, 8, 1, 3, 7, 6, 14, 12, 19, 16, 18, 2, 4, 11, 5, 9, 13, 20, 17, 15, 10, 8, 3, 1, 7, 6, 12, 14, 16, 19, 17, 18, 2, 4, 9, 11, 5, 13, 20, 15, 10, 12, 8, 3, 1, 14, 7, 6, 16, 19, 2, 17, 18, 4, 9, 11, 5, 20, 13, 15, 10, 12, 8, 3, 1, 14, 7, 6, 16, 19, 2, 17, 18, 20, 4, 9, 11, 15, 5, 13, 10, 12, 8, 14, 7, 6, 3, 1, 16, 19, 
    2, 20, 17, 18, 4, 9, 11, 5)
    nWorkers = 20
    cls = makeCluster(nWorkers)
    c.data.frame = rbind
    clusterExport(cls, c("dyncut", "npbin"))
    clusterExport(cls, c("assignments", "c.data.frame"))
    parLapply(cls, seq(nWorkers), function(i) assign("workerID", i, globalenv()))
    clusterEvalQ(cls, {
        assignments = which(assignments == workerID)
        NULL
    })
}
{
    clusterEvalQ(cls, {
        read_args = c("/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_01.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_02.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_03.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_04.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_05.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_06.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_07.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_08.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_09.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_10.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_11.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_12.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_15.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_16.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_17.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_18.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_19.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_20.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_21.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_22.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_23.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_24.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_25.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_26.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_27.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_28.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_29.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_30.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_01_31.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_01.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_02.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_03.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_04.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_05.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_06.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_07.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_08.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_09.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_10.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_11.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_12.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_13.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_14.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_15.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_16.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_17.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_18.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_19.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_20.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_21.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_22.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_23.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_24.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_25.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_26.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_27.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_28.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_02_29.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_01.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_02.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_03.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_04.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_05.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_06.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_07.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_08.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_09.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_10.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_11.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_12.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_13.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_14.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_15.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_16.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_17.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_18.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_19.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_20.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_21.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_22.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_23.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_24.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_25.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_26.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_27.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_28.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_29.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_30.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_03_31.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_01.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_02.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_03.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_04.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_05.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_06.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_07.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_08.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_09.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_10.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_11.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_12.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_13.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_14.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_15.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_16.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_17.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_18.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_19.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_20.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_21.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_22.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_23.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_24.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_25.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_26.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_27.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_28.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_29.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_04_30.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_01.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_02.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_03.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_04.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_05.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_06.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_07.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_08.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_09.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_10.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_11.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_12.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_13.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_14.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_15.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_16.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_17.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_18.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_19.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_20.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_21.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_22.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_23.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_24.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_25.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_26.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_27.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_28.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_29.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_30.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_05_31.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_01.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_02.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_03.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_04.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_05.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_06.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_07.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_08.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_09.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_10.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_11.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_12.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_13.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_14.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_15.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_16.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_17.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_18.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_19.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_20.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_21.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_22.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_23.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_24.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_25.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_26.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_27.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_28.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_29.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_06_30.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_01.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_02.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_03.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_04.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_05.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_06.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_07.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_08.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_09.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_10.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_11.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_12.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_13.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_14.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_15.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_16.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_17.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_18.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_19.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_20.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_21.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_22.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_23.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_24.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_25.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_26.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_27.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_28.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_29.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_30.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_07_31.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_01.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_02.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_03.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_04.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_05.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_06.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_07.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_08.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_09.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_10.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_11.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_12.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_13.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_14.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_15.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_16.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_17.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_18.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_19.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_20.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_21.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_22.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_23.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_24.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_25.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_26.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_27.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_28.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_29.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_30.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_08_31.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_01.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_02.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_03.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_04.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_05.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_06.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_07.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_08.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_09.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_10.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_11.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_12.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_13.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_14.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_15.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_16.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_17.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_18.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_19.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_20.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_21.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_22.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_23.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_24.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_25.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_26.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_27.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_28.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_29.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_09_30.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_01.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_02.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_03.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_04.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_05.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_06.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_07.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_08.txt.gz", 
        "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_09.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_10.txt.gz", "/scratch/clarkf/pems/district4/d04_text_station_raw_2016_10_11.txt.gz")
        read_args = read_args[assignments]
        chunks = lapply(read_args, read.csv, col.names = c("timeperiod", "station", "flow1", "occupancy1", "speed1", "flow2", "occupancy2", "speed2", "flow3", "occupancy3", "speed3", "flow4", "occupancy4", "speed4", "flow5", "occupancy5", "speed5", "flow6", "occupancy6", "speed6", "flow7", "occupancy7", "speed7", "flow8", "occupancy8", "speed8"), colClasses = c("character", "integer", "integer", "numeric", "numeric", "integer", "numeric", "numeric", "integer", "numeric", "numeric", "integer", "numeric", 
        "numeric", "integer", "numeric", "numeric", "integer", "numeric", "numeric", "integer", "numeric", "numeric", "integer", "numeric", "numeric"), header = FALSE)
        pems = do.call(c, chunks)
        NULL
    })
}
cols = c("station", "flow2", "occupancy2")
clusterExport(cls, "cols")
clusterEvalQ(cls, {
    {
        pems = pems[, cols]
        station = pems[, "station"]
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
    split_assignments = makeParallel:::greedy_assign(group_counts, 20)
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
    results = lapply(pems2, npbin)
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
results = do.call(rbind, results)
write.csv(results, "results.csv", row.names = FALSE)
stopCluster(cls)
