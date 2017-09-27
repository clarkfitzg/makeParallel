# Fri Sep 22 11:26:16 PDT 2017
# Tools to transform R code into a "canonical form"

# Sun Sep 24 14:53:01 PDT 2017
# Not currently worrying about:
# - logical subsetting of columns
# - non unique column names




# 2. Identify all calls which subset \code{varname} and transform them into a common
# form
#'
#' @param statement code which may or may not be subsetting the data frame
#' @param varname string containing name of data frame
#' @return list with all relevant information
canon_form = function(statement, varname, colnames)
{
    default = list(transformed = statement
         , column_indices = NULL
         )

    varlocs = findvar(statement, varname)

    # Early out, varname doesn't appear in the statement
    if(length(varlocs) == 0){
        return(default)
    }

    # Was one of the known subset functions called with varname as the
    # first argument?

    lapply(varlocs, 

}


#' Replace $ with [
#'
#' Designed for use only with a single call of the form \code{x$y}, where x
#' is a data.frame.
#' @export
dollar_to_ssb = function(statement, colnames)
{
    template = quote(dframe[, index])
    column_name = deparse(statement[[3]])
    column_index = which(colnames == column_name)[1]
    statement = sub_expr(template,
            list(dframe = statement[[2]], index = column_index))
    list(statement = statement, column_indices = column_index)
}


#' Replace [[ with [
#'
#' @export
double_to_ssb = function(statement, colnames)
{

    template = quote(dframe[, index])

    column = statement[[3]]

    column_index = if(is.numeric(column)){
        if(length(column) > 1) stop("Recursive indexing not currently supported")
        column
    } else if(is.character(column)){
        which(colnames == column)[1]
    } else {
        stop("Expected character or numeric for `[[` indexing")
    }

    statement = sub_expr(template,
            list(dframe = statement[[2]], index = column_index))
    list(statement = statement, column_indices = column_index)
}


#' Replace column subset [ possibly using names with [ using integers
#'
#' @export
single_to_ssb = function(statement, colnames)
{

    column = statement[[4]]

    if(class(column) == "call"){
        if(only_literals(column)){
            column = eval(column)
        } else {
            stop("Not a literal expression")
        }
    }

    column_index = if(is.numeric(column)){
        column
    } else if(is.character(column)){
        which(colnames %in% column)
    } else {
        stop("Expected character or numeric for `[` indexing")
    }

    statement[[4]] = column_index
    list(statement = statement, column_indices = column_index)
}


subset_funcs = list(`$` = dollar_to_ssb
                    , `[[` = double_to_ssb
                    , `[` = single_to_ssb
                    )


#' Extract the part of the parse tree which subsets varname
subtree = function(varloc, statement, varname)
{
    parent = statement[[varloc[-length(varloc)]]]

}

