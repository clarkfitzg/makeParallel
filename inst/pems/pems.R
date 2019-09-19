# This is the high level code that I would *like* to run. It won't work
# because it will run out of memory

message("starting")
old_time = Sys.time()



dyncut = function(x, pts_per_bin = 200, lower = 0, upper = 1, min_bin_width = 0.01)
{
    x = x[x < upper]
    N = length(x)
    max_num_cuts = ceiling(upper / min_bin_width)
    eachq = pts_per_bin / N

    possible_cuts = quantile(x, probs = seq(from = 0, to = 1, by = eachq), na.rm = TRUE)
    cuts = rep(NA, max_num_cuts)
    current_cut = lower
    for(i in seq_along(cuts)){
        # Find the first possible cuts that is at least min_bin_width away from
        # the current cut
        possible_cuts = possible_cuts[possible_cuts >= current_cut + min_bin_width]
        if(length(possible_cuts) == 0) 
            break
        current_cut = possible_cuts[1]
        cuts[i] = current_cut
    }
    cuts = cuts[!is.na(cuts)]
    c(lower, cuts, upper)
}


# Non parametric binned means
npbin = function(x)
{
    breaks = dyncut(x$occupancy2, pts_per_bin = 200)
    binned = cut(x$occupancy2, breaks, right = FALSE)
    groups = split(x$flow2, binned)

    out = data.frame(station = rep(x[1, "station"], length(groups))
        , right_end_occ = breaks[-1]
        , mean_flow = sapply(groups, mean)
        , sd_flow = sapply(groups, sd)
        , number_observed = sapply(groups, length)
    )
    out
}


# Actual program
############################################################
#
# - Load data
# - Split based on column value
# - Apply a function to each group
# - Write the result

# We'll generate the reading code

# From this line we can infer that we only need these 3 columns.
# How do we know for sure?
# Because it writes over the pems variable.
# I wrote code to do this in the CodeAnalysis package.
cols = c("station", "flow2", "occupancy2")
pems = pems[, cols]
 
new_time = Sys.time()
message("read in files and rbind: ", capture.output(new_time - old_time))
old_time = new_time

# The data description will tell us if the data starts grouped by the "station" column
station = pems[, "station"]
pems2 = split(pems, station)

new_time = Sys.time()
message("split: ", capture.output(new_time - old_time))
old_time = new_time

results = lapply(pems2, npbin)

new_time = Sys.time()
message("actual computations: ", capture.output(new_time - old_time))
old_time = new_time

results = do.call(rbind, results)

write.csv(results, "results.csv", row.names = FALSE)

new_time = Sys.time()
message("save output: ", capture.output(new_time - old_time))
old_time = new_time
