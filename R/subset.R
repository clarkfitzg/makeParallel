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


# 6. Transform the calls which subset `d` into new indices.
update_indices = function(statement, index_locs, index_map)
{
    # for loops necessary for making incremental changes and avoiding the
    # need to merge.
    for(loc in index_locs){

        # If it's not a literal scalar then we assume here it's something like
        # x[, c(5, 20)] so that the inside can be evaluated.
        # It's preferable to check this assumption in an earlier step
        # rather than here because if the inside cannot be evaluated in a
        # simple way then we don't actually know which columns are being used
        # so this code should never run.

        # It's important to evaluate the original code rather than
        # just substituting, because the meaning could potentially change.
        # I'm thinking of something like seq(1, 20, by = 4)

        original = eval(statement[[loc]])
        converted = sapply(original, function(x) which(x == index_map))
        statement[[loc]] = converted
    }
    statement
}
