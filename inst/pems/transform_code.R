library(makeParallel)

# The named list for the data argument means that the symbol 'pems' in the code corresponds to the data in 'pems_ds'.
makeParallel("pems.R", data = list(pems = pems_ds), workers = 10L)
