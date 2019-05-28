pems_1 = pipe("cut -d , -f station,flow2,occupancy2 stationID/313368.csv")
pems_2 = pipe("cut -d , -f station,flow2,occupancy2 stationID/313369.csv")

pems = pems[, c("station", "flow2", "occupancy2")]
pems2 = split(pems, pems$station)
results = lapply(pems2, npbin)
results = do.call(rbind, results)
write.csv(results, "results.csv")
