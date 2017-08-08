# From wlandau
# https://github.com/duncantl/CodeDepends/issues/19

library(CodeDepends)


# TODO: Modify this to work without requiring that the code be evaluated
# Probably means we can't use codetools::findGlobals
#
#' fun closure, see codetools::findGlobals
#' possible_funs character vector of variable names to recurse into
findGlobals_recursive <- function(fun, possible_funs)
{
    globals <- codetools::findGlobals(fun)

    for(varname in intersect(globals, possible_funs)){
        var = get(varname, envir = .GlobalEnv)
        if(is.function(var)){
            globals <- c(globals, Recall(var, possible_funs))
        }
    }
    unique(globals)
}


# Usage
############################################################

code = parse(text = "
f <- function(x) g(x)
g <- function(x) {
    h(x)
}
h <- function(x) {
      sin(x) + cos(x) + my_var
}
my_var <- 1
")

eval(code)


info = getInputs(code)

findGlobals_recursive(f, info@outputs)
