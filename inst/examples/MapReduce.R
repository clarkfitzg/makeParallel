# Tue Aug 15 09:25:48 PDT 2017
# 
# Goal: automatically parallelize this
#

x = as.list(1:10)
y = Map(function(xi) 2 * xi, x)
sy = Reduce(`+`, y)                 # Push partially to worker
z = Map(function(yi) yi - 3 + sy, y)     # Never bring to manager
sz = Reduce(`+`, z)                 # Push to worker
print(sz)

