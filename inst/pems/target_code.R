# This is what pems.R should be expanded to before feeding it to the list scheduler.
# The list scheduler should be able to handle the following code directly.
# A 
#

# omit the function bodies for brevity here- they will actually be included.
dyncut = function(...) "see pems.R"

npbin = function(...) "see pems.R"


# We can expand in this way because we saw the combination of the following:
#
# 1. A split based on a data partition
# 2. An lapply on the results of that split

pems2_1 = read.csv(
    pipe("cut -d , -f 2,6,7 stationID/313368.csv")
    , col.names = c("station", "flow2", "occupancy2")
    , colClasses = c("integer", "integer", "numeric")
    )
    
pems2_2 = read.csv(
    pipe("cut -d , -f 2,6,7 stationID/313369.csv")
    , col.names = c("station", "flow2", "occupancy2")
    , colClasses = c("integer", "integer", "numeric")
    )
    
pems2_1 = split(pems_1, pems_1$station)
pems2_2 = split(pems_2, pems_2$station)

results_1 = lapply(pems2_1, npbin)
results_2 = lapply(pems2_2, npbin)

results = c(results_1, results_2)

# Unmodified after this point
results = do.call(rbind, results)

write.csv(results, "results.csv")
