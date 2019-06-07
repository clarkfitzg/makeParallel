pipe("cut -d , -f  stationID/313368.csv")
pipe("cut -d , -f  stationID/313369.csv")
pems = pems[, c("station", "flow2", "occupancy2")]
pems2 = split(pems, pems$station)
results = lapply(pems2, npbin)
results = do.call(rbind, results)
write.csv(results, "results.csv")
