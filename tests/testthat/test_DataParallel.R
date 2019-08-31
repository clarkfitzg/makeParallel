# DataParallel has several tests which are contained in directories, but have very similar structure.
# This function exercises these tests and integrates with testthtat.
run_DataParallel = function(path){
    setwd(dirname(path))
    on.exit(setwd(".."))
    source(basename(path))
}


lapply(c("map_reduce_example/test.R"
    , "two_blocks/test.R"
), run_DataParallel)
