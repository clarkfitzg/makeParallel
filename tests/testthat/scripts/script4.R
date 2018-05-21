# The ping pong script. Assignments to a* should happen on worker 1,
# assignments to b* should happen on worker 2.

a1 = 1
b1 = 1
a2 = 2
b2 = 2

a3 = a1 + a2 + b2
b3 = b1 + b2 + a2

a4 = a2 + a3 + b3
b4 = b2 + b3 + a3

a5 = a3 + a4 + b4
b5 = b3 + b4 + a4

writeLines(as.character(a5), "out4a.log")
writeLines(as.character(b5), "out4b.log")
