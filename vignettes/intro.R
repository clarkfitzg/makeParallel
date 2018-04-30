## ----setup, include = FALSE----------------------------------------------
knitr::opts_chunk$set(
    eval = FALSE
)

## ------------------------------------------------------------------------
#  
#  library(autoparallel)
#  
#  autoparallel("code.R")

## ------------------------------------------------------------------------
#  pcode = parallelize("code.R"
#      , clean_first = FALSE
#      , run_now = FALSE
#      , cluster_type = "FORK"
#      , nnodes = 4
#  )
#  
#  # visual representation of the graph structure
#  plot(pcode)
#  
#  # Save the parallel version of the script
#  save_code(pcode, "pcode.R")
#  
#  # Run the whole thing interactively
#  run_code(pcode)

