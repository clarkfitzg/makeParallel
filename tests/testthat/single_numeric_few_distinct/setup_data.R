# Set up some toy data
n = 100
nDistinct = 10L
set.seed(3890)
vals = rnorm(nDistinct)

saveRDS(sample(vals, size = n, replace = TRUE), "small1.rds", compress = FALSE)
saveRDS(sample(vals, size = n, replace = TRUE), "small2.rds", compress = FALSE)
saveRDS(sample(vals, size = 2 *n, replace = TRUE), "big.rds", compress = FALSE)
