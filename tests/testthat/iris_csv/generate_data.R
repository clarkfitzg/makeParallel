set.seed(803)
random_ints = sample(5L, size = nrow(iris), replace = TRUE)
s = split(iris, random_ints)
Map(write.csv, s, paste0(names(s), ".csv"))
