# This is the target for the transformed program, ie.
# whatever codedoctor spits out should look something like this.
#
# This requires an associative Reduce function, different from R.

library(parallel)

cl = makeCluster(2L)

x = as.list(1:10)

codedoctor::assign_workers(cl, "x")


# Relying on `{` returning the last statement, and the `=` assignment
# operator returning the object of assignment
sy_partial_reduce = clusterEvalQ(cl, {
    y = Map(function(xi) 2 * xi, x)
    sy = Reduce(`+`, y)
})
sy = Reduce(`+`, sy_partial_reduce)

clusterExport(cl, "sy")

sz_partial_reduce = clusterEvalQ(cl, {
    z = Map(function(yi) yi - 3 + sy, y)
    sz = Reduce(`+`, z)
})
sz = Reduce(`+`, sz_partial_reduce)

print(sz)

