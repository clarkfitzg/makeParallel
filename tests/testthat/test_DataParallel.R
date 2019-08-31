# DataParallel has several tests which are contained in directories, but have very similar structure.
# This function exercises these tests and integrates with testthtat.
run_DataParallel = function(path){
    setwd(dirname(path))
    on.exit(setwd(".."))
    source(path)
}


lapply(run_DataParallel, c("map_reduce_example/transform.R"
                           , "two_blocks/transform.R"
                           ))
