# Sends a big object over
x = 1
tenmb = seq(10 * 2^20/4)
y = 2
out = sum(x, y, tenmb)
write.table(out, "out6.log")
