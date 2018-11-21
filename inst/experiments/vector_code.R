# Some vectorized code operating on x.
# Suppose x is a huge vector stored on disk, and we would like to
# use it to compute y.

#x = readRDS("x.rds")
x = read("x.rds")

cond = x < 0
tmp = x[cond]

x[cond] = exp(tmp)

#y = x # Making it follow the structure I want:
#y = identity(x)

# . represents no actual assignment here.
#. = plot(x)

. = save(x, "x2.rds")
