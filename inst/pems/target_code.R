# This is what pems.R should be expanded to before feeding it to the list scheduler.
# The list scheduler should be able to handle the following code directly.
# A 
#

# omit the function bodies for brevity here
dyncut = function(...) "see pems.R"

npbin = function(...) "see pems.R"


# We can expand in this way because we saw the combination of the following:
#
# 1. A split based on a data partition
# 2. An lapply on the results of that split

pems2_313368 = read.csv(
    pipe("cut -d , -f 2,6,7 stationID/313368.csv")
    , col.names = c("station", "flow2", "occupancy2")
    , colClasses = c("integer", "integer", "numeric")
    )
    
results_313368 = npbin(pems_313368)


pems2_313369 = read.csv(
    pipe("cut -d , -f 2,6,7 stationID/313369.csv")
    , col.names = c("station", "flow2", "occupancy2")
    , colClasses = c("integer", "integer", "numeric")
    )
    
results_313369 = npbin(pems_313369)
 
# At this point we just gather up what would be the results of the lapply, because the next line is a `do.call`, which is a general function.
# If it was instead a vectorized function, then we could expand it.
results = list(results_313368, results_313369)

results = do.call(rbind, results)

write.csv(results, "results.csv")
