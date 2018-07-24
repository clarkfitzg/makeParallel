# Sends a big object over
x = 1
tenmb = as.numeric(seq(10 * 2^20/8))
y = 2
out = sum(x, y, tenmb)
write.table(out, "script6.R.log")
