# DataParallel has several tests which are contained in directories, but have very similar structure.
# This function exercises these tests and integrates with testthtat.
run_DataParallel = function(dir){
    setwd(dir)
    on.exit(setwd(".."))

    source("transform.R")
}


lapply(run_DataParallel, c("map_reduce_example", "two_blocks"))
