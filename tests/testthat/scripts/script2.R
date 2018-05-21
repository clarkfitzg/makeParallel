# worker 1
a = 7
b = a + 4
# worker 2
x = 1
y = x + 2
# worker 1
c = b + y
# If the work is assigned as above then worker 1 will have variables c and
# y, while worker 2 will have variables x and y. As I've implemented it,
# ties should go to the lower worker, so worker 1 should do this. But I
# don't think I've added the logic so that we know variable y is available
# on worker 1. Thus 2 should do the following:
output = c("got:", c*x*y, "expected:", (7 + 4 + 1 + 2) * 1 * (1 + 2))
writeLines(output, "out2.log")
