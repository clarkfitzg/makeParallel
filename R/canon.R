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
    default = list(found = FALSE
         , transformed = statement
         , column_indices = NULL
         )

    subset_func_names = c("[", "$", "[[")

    # Early out, not a top level subset
    if(!(as.character(statement[[1]]) %in% subset_func_names)) return(default)

    # TODO: What about: y = x[, 1]
    # A better way to do this is to find all place the variable of
    # interest, say y, occurs and then work backwards from there, seeing if
    # it's the argument to a subset func.

    # Early out, not subsetting the variable of interest
    if(!(as.character(statement[[2]]) %in% subset_func_names)) return(default)
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
