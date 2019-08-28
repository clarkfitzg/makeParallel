# Set up some toy data
n = 100
small = seq(from = 0, to = 1, length.out = n)

saveRDS(small, "small1.rds", compress = FALSE)
saveRDS(small, "small2.rds", compress = FALSE)

big = c(small, small)
saveRDS(big, "big.rds", compress = FALSE)
