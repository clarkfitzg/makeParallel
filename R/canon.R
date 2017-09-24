# Fri Sep 22 11:26:16 PDT 2017
# Tools to transform R code into a "canonical form"

# Sun Sep 24 14:53:01 PDT 2017
# Not currently worrying about:
# - logical subsetting of columns
# - non unique column names


#' Replace Names With Indices
#'
#' @example
#' code = 
#' names_to_ssb(
names_to_ssb = function(statement, names)
{

    # Maybe the way to implement this is through CodeDepends dollarhandler?


    col = CodeDepends::inputCollector(`$` = function(e, collector, ...) {
        browser()
        CodeDepends::defaultFuncHandlers$`$`(e, collector, ...)
    })

    a = CodeDepends::getInputs(statement, collector = col)   

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

    if(column[[1]] == quote(c)){
        # This could easily get complicated...
        # c(1L, "x")
        # c(1L, f())
        # Could check for calls to any other function besides c(), and
        # raise an error.
        # Related:
        # 1:5

        # TODO: Assume for the moment they're all literals:
        column = eval(column)
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
