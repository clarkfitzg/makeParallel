# Fri Sep 22 11:26:16 PDT 2017
# Tools to transform R code into a "canonical form"

#' Replace Names With Indices
#'
#' @example
#' code = 
#' names_to_index(
names_to_index = function(statement, names)
{

    # Maybe the way to implement this is through CodeDepends dollarhandler?


    col = CodeDepends::inputCollector(`$` = function(e, collector, ...) {
        browser()
        CodeDepends::defaultFuncHandlers$`$`(e, collector, ...)
    })

    a = CodeDepends::getInputs(statement, collector = col)   

}


#' Replace Dollar With Square Bracket
#'
#' Designed for use only with a single call of the form \code{x$y}.
#' @export
dollar_to_index = function(statement, colnames)
{
    template = quote(dframe[, index])
    column_name = deparse(statement[[3]])
    column_index = which(colnames == column_name)[1]
    statement = sub_expr(template,
            list(dframe = statement[[2]], index = column_index))
    list(statement = statement, column_indices = column_index)
}


#' D
#'
#' @export
double_to_single_bracket = function(statement)
{
    # Be careful here because `[[` supports recursive indexing.
}


