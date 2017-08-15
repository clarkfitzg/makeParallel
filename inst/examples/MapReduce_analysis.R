library(CodeDepends)

s = readScript("MapReduce.R")

g = autoparallel::depend_graph(s)

# Find if a variable assigned to a Map result is only input to a Reduce.
# If so, then we can combine the Map and Reduce. But is this the best way?

mapuse = sapply(s, autoparallel::apply_location, apply_func = "Map")

# Making assumptions on how code is written here, ie. x = Map(...)
map_assign = which(mapuse == 3)

names(map_assign) = sapply(s[map_assign], `[[`, 2)

# Next: find out where they are inputs
