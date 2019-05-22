#' Expand Data Description
#'
#' Insert the chunked data loading calls directly into the code, expand vectorized function calls,
#' and collect variables before calling non vectorized function calls.
#'
#' @export
#' @rdname scheduleTaskList
setMethod("expandData", signature(code = "DependGraph", data = "list"),
function(code, data, ...)
{
    graph = code
    dataLoadExpr = data
    if(length(dataLoadExpr) == 0) return(graph)

    # TODO: It probably makes more sense to loop and dispatch on every one of these arguments,
    # rather than assuming it is a list of chunkedData objects.

    chunkLoadCode = lapply(dataLoadExpr, slot, "expr")

    mangledNames = Map(appendNumber, names(chunkLoadCode), chunkLoadCode)

    initialAssignments = mapply(initialAssignmentCode, mangledNames, chunkLoadCode, USE.NAMES = FALSE)

    vars = list(expanded = mangledNames
                , collected = c())

    oldCode = graph@code
    newExpressions = vector(mode = "list", length = length(oldCode))

    for(i in seq_along(oldCode)){
        expr = oldCode[[i]]
        tmp = expandCollect(expr, vars)
        vars = tmp$vars
        newExpressions[[i]] = tmp$expr
    }

    newCode = do.call(c, newExpressions)

    completeCode = c(initialAssignments, newCode)
    inferGraph(completeCode)
})


# TODO: check that this name mangling scheme is not problematic.
# Also, could parameterize these functions.
appendNumber = function(varname, obj, n = seq_along(obj), sep = "_")
{
    paste0(varname, sep, n)
}


# Generate code to do the initial assignment
initialAssignmentCode = function(varname, code)
{
    nm = lapply(varname, as.symbol)
    out = mapply(call, '=', nm, code, USE.NAMES = FALSE)
    as.expression(out)
}


# returns updated versions of vars and expr in a list
# expr is an expression rather than a single call, because this function will turn a single call into many.
expandCollect = function(expr, vars)
{
#    for(v in names(vars$expanded)){
#        found = find_var(expr, v)
#        for(loc in found){
#            usage = expr[[loc[-length(loc)]]]
#            if(is.call(usage) 
#               && as.character(usage[[1]]) %in% vectorfuncs 
#               ){
#                expandVector(expr, v)
#            } else {
#                collectVector(expr, v)
#            }
#        }
#    }
    # Yuck this is a mess.
    # Instead, I can start out just handling statements that look like:
    # y = f(x, z, ...)


    vars_in_expr = sapply(names(vars$expanded), function(var){
        finds = find_var(expr, var)
        if(0 < length(finds)) var else NULL
    })
    
    if(0 < length(vars_in_expr)){
        if(isSimpleAssignFunc(expr)){
            expandVector(expr, vars)
        } else {
            # Variable appears in the expression, but the expression is not a simple assign,
            # so we treat it as a general function call.
            collectVector(expr, vars)
        }
    } else {
        # No chunked variables appear, don't change it.
        list(vars = vars, expr = expr)
    }
}


# Take a single vectorized call and expand it into many calls.
expandVector = function(expr, vars)
{
    rhs = expr[[3]]
    function_name = as.character(rhs[[1]])
    if(!function_name %in% vectorfuncs){
        return(collectVector(expr, vars))
    }

    function_args = as.character(rhs[-1])
    names_to_expand = intersect(names(vars$expanded), function_args)

    lhs = as.character(expr[[2]])

    # Record the lhs as now being an expanded variable
    # TODO: Check that the variables have the same number of chunks.
    first_one_var_names =  vars$expanded[[names_to_expand[1]]]
    vars$expanded[[lhs]] = appendNumber(lhs, first_one_var_names)

    names_to_expand = c(names_to_expand, lhs)

    newexpr = expandExpr(expr, vars$expanded[names_to_expand])

    list(vars = vars, expr = newexpr)
}


# vars_to_expand is a list like list(a = c("a1", "a2"), b = c("b1", "b2"))
# This function then does the actual expansion.
#
# Before:
# b = f(a)
#
# After:
# b1 = f(a1)    # <-- This is what expand means
# b2 = f(a2)
#
expandExpr = function(expr, vars_to_expand)
{

    iterator = seq_along(vars_to_expand[[1]])

    # Initialize
    newexpr = lapply(iterator, function(...) expr)

    for(i in iterator){
        varname_lookup = lapply(vars_to_expand, function(var) as.symbol(var[i]))
        newexpr[[i]] = substitute_q(expr, varname_lookup)
    }
    as.expression(newexpr)
}


# collect vectorized variables that expr uses and are not already collected.
#
# Before:
# f(x)
#
# After:
# x = c(x1, x2, ..., xk)  # <-- this is what collect means
# f(x)
#
collectVector = function(expr, vars)
{
    vars_used = CodeDepends::getInputs(expr)@inputs
    vars_to_collect = intersect(vars_used, names(vars$expanded))

    # If the variable has already been collected, then we don't need to do it again.
    vars_to_collect = setdiff(vars_to_collect, vars$collected)

    collect_code = Map(collectOneVariable, vars_to_collect, vars$expanded[vars_to_collect])

    collect_code_all_vars = do.call(c, unname(collect_code))

    vars$collected = c(vars$collected, vars_to_collect)

    list(vars = vars, expr = c(collect_code_all_vars, expr))
}


collectOneVariable = function(vname, chunked_varnames)
{
    # Easier to build it from the strings.
    args = paste(chunked_varnames, collapse = ", ")
    expr = paste(vname, "= c(", args, ")")
    parse(text = expr)
}


# Verify that expr has the form
# y = f(x1, x2, ..., xn)
isSimpleAssignFunc = function(expr)
{
    result = FALSE
    if(expr[[1]] == "="){
        rhs = expr[[3]]
        if(is.call(rhs) && !any(sapply(rhs, is.call))){
            # rhs is a single, non nested call
            result = TRUE
        }
    }
    result
}


if(FALSE){
    # developing, may move these to tests eventually

    dataLoadExpr = list(x = makeParallel:::ChunkDataSource(expr=parse(text = "1 + 2
              3 + 4")))

    expr = parse(text = "y = x + 2")[[1]]

    find_var = makeParallel:::find_var

    vars = list(a = "alpha", b = "bravo")
    vars = lapply(vars, as.symbol)
    e = quote(a + b)
    substitute_q(e, vars)

vars_to_expand = list(a = c("a1", "a2"), b = c("b1", "b2"))

expandExpr(e, vars_to_expand)

    CodeDepends::getInputs(expr)@inputs

    collectOneVariable("x", c("x_1", "x_2", "x_3"))

}


# TODO:
# - Make user extensible
# - Identify which arguments they are vectorized in
vectorfuncs = c("*")

# https://cran.r-project.org/doc/manuals/r-release/R-lang.html#Substitutions
# http://adv-r.had.co.nz/Computing-on-the-language.html#substitute
substitute_q <- function(x, env) {
      call <- substitute(substitute(y, env), list(y = x))
  eval(call)
}



#' @rdname scheduleTaskList
setMethod("expandData", signature(code = "expression", data = "DataFiles"),
function(code, data, ...)
{

})
