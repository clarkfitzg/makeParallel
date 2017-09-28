# Mon Sep 25 12:12:58 PDT 2017
#
# Implementing method described in transpile vignette:
#
# 1. Infer that a data frame `d` is created by a call to `read.csv()`
# 2. Identify all calls which subset `d` and transform them into a common
#    form.
# 4. Find `usedcolumns` the set of all columns which are used
# 5. Transform the `read.csv(...)` call into `data.table::fread(..., select =
#    usedcolumns)`
# 6. Transform the calls which subset `d` into new indices.


#' 1. Infer that a data frame is created by a call to `read.csv()`
#'
#' Currently only handles top level assignment.
#'
#' @return symbol name of data.frame, or NULL if none found
data_read = function(statement, assigners = c("<-", "=", "assign")
                     , readers = c("read.csv", "read.table"))
{
    if(as.character(statement[[1]]) %in% assigners){
        funcname = as.character(statement[[c(3, 1)]])
        if(funcname %in% readers){
            return(as.symbol(statement[[2]]))
        } 
    }
    NULL
}


#
# 6. Transform the calls which subset `d` into new indices.
update_indices = function(statement, index_locs, index_map)
{
}
