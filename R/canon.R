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

    col = CodeDepends::inputCollector(dollarhandler = function(e, collector, ...) {
        print(paste("Hello", asVarName(e)))
        defaultFuncHandlers$dollarhandler(e, collector, ...)
    })

    a = CodeDepends::getInputs(statement, collector = col)   

}
