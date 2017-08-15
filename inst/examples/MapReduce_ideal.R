# This is the target for the transformed program, ie.
# whatever autoparallel spits out should look something like this.

library(parallel)

cl = makeCluster(2L)

x = as.list(1:10)

y = Map(function(xi) 2 * xi, x)
y = clusterMap(cl, function(xi) 2 * xi, x)

sy = Reduce(`+`, y)                 # Push partially to worker
z = Map(function(yi) yi - 3, y)     # Never bring to manager
sz = Reduce(`+`, z)                 # Push to worker


