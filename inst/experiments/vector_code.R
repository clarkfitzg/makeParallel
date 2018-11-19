# Some vectorized code operating on x.
# Suppose x is a huge vector stored on disk, and we would like to
# use it to compute y.

cond = x < 0
tmp = x[cond]
x[cond] = exp(tmp)
y = x
