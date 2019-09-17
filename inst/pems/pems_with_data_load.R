# This is the high level code that I would *like* to run. It won't work
# because it will run out of memory


dyncut = function(x, pts_per_bin = 200, lower = 0, upper = 1, min_bin_width = 0.01)
{
    x = x[x < upper]
    N = length(x)
    max_num_cuts = ceiling(upper / min_bin_width)
    eachq = pts_per_bin / N

    possible_cuts = quantile(x, probs = seq(from = 0, to = 1, by = eachq))
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
files = list.files("data", full.names = TRUE)

col.names = c("timeperiod", "station"
    , "flow1", "occupancy1", "speed1"
    , "flow2", "occupancy2", "speed2"
    , "flow3", "occupancy3", "speed3"
    , "flow4", "occupancy4", "speed4"
    , "flow5", "occupancy5", "speed5"
    , "flow6", "occupancy6", "speed6"
    , "flow7", "occupancy7", "speed7"
    , "flow8", "occupancy8", "speed8"
    )

colClasses = columns = c(timeperiod = "NULL", station = "integer"
    , flow1 = "NULL", occupancy1 = "NULL", speed1 = "NULL"
    , flow2 = "integer", occupancy2 = "numeric", speed2 = "NULL"
    , flow3 = "NULL", occupancy3 = "NULL", speed3 = "NULL"
    , flow4 = "NULL", occupancy4 = "NULL", speed4 = "NULL"
    , flow5 = "NULL", occupancy5 = "NULL", speed5 = "NULL"
    , flow6 = "NULL", occupancy6 = "NULL", speed6 = "NULL"
    , flow7 = "NULL", occupancy7 = "NULL", speed7 = "NULL"
    , flow8 = "NULL", occupancy8 = "NULL", speed8 = "NULL"
    )

pems = lapply(files, read.csv, col.names = col.names, colClasses = colClasses)
pems = do.call(rbind, pems)
 
# The data description will tell us if the data starts grouped by the "station" column
station = pems[, "station"]
pems2 = split(pems, station)

results = lapply(pems2, npbin)

results = do.call(rbind, results)

write.csv(results, "results.csv", row.names = FALSE)
