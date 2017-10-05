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


# 5. Transform the `read.csv(...)` call into `data.table::fread(..., select =
#    usedcolumns)`
# @xport
to_fread = function(statement, select)
{
    transformed = statement
    transformed[[1]] = quote(data.table::fread)
    # Sometimes R just makes things too easy! So happy with this:
    transformed[["select"]] = as.integer(select)
    transformed
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


assigners = c("<-", "=", "assign")
readers = c("read.csv", "read.table")


#' Transform To Faster Reads
#'
#' Reduce run time and memory use by transforming an expression to read only the
#' columns of a data frame that are necessary for the remainder of the
#' expression.
#'
#' @param expression, for example as returned from \code{base::parse}
#' @param varname character naming the data frame of interest
#' @param colnames column names for the data frame of interest
#'
#' @return transformed code
#' @export
read_faster = function(expression, varname = NULL, colnames = NULL)
{

    nulls = c(is.null(varname), is.null(colnames))

    # Easy out if both are specified
    if(all(!nulls)){
        return(read_faster_work(expression, varname, colnames))
    }

    if(any(!nulls)){
        stop("Must specify both varname and colnames.")
    }

    out = expression
    for(reader in readers){
        readlocs = find_var(expression, reader)
        for(loc in readlocs){
            depth = length(loc)
            possible_assign = expression[[loc[-c(depth - 1, depth)]]]
            if(as.character(possible_assign[[1]]) %in% assigners){
                varname = possible_assign[[2]]
                # TODO: 
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# INFER COLNAMES
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                out = read_faster_work(out, varname, colnames = letters)
            }
        }
    }
    out
}


#' Infer Names And Columns Of Data Frames
#'
#'
#' @return list, with each element a list containing data frame variable
#'  names and column names
infer_read_var = function(expression)
{
}


read_faster_work = function(expression, varname, colnames)
{
    analyzed = lapply(expression, canon_form, varname = varname, colnames = colnames)

    column_indices = lapply(analyzed, `[[`, "column_indices")
    index_map = sort(unique(do.call(c, column_indices)))

    transformed = lapply(analyzed, `[[`, "transformed")

    index_locs = lapply(analyzed, `[[`, "index_locs")

    output = mapply(update_indices, transformed, index_locs
                 , MoreArgs = list(index_map = index_map))
    output = as.expression(output)

    # TODO:
    # - May want to move some of the following logic into a wrapper
    #   function since some is common across variables.
    # - Other read funcs

    readlocs = find_var(output, "read.csv")

    subset_read_inserted = FALSE

    for(loc in readlocs){
        n = length(loc)
        parentloc = loc[-c(n-1, n)]
        parent = output[[parentloc]]
        if(as.character(parent[[1]]) %in% assigners){
            if(parent[[2]] == varname){
                # TODO: Assuming here the assignment statment looks like
                # x = read.csv(...)
                insertion_loc = loc[-n]
                output[[insertion_loc]] = to_fread(output[[insertion_loc]]
                                                   , select = index_map)
                subset_read_inserted = TRUE
                break
            }
        }
    }

    if(!subset_read_inserted) stop("Data reading call didn't change.")

    output
}
