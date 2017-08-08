# From wlandau
# https://github.com/duncantl/CodeDepends/issues/19

f <- function(x) g(x)
g <- function(x) {
    h(x)
}
h <- function(x) {
      sin(x) + cos(x) + my_var
}
my_var <- 1


findGlobals_recursive <- function(fun)
#
{
    globals <- codetools::findGlobals(fun)

    for(varname in globals){
        var = get(varname, envir = .GlobalEnv)
        if(is.function(var)){
            globals <- c(globals, findGlobals_recursive(var))
        }
    }
    
    unique(globals)
}


findGlobals_recursive(f)

codetools::findGlobals(g)
# The difficulty is that `{` is a global function!

codetools::findGlobals(h)
