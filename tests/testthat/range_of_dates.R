dt = read.table('dates.txt')
d = as.Date(dt[, 1])
rd = range(d)
print(rd)
