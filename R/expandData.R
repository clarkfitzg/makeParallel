#' Expand Data Description
#'
#' Insert the chunked data loading calls directly into the code, expand vectorized function calls,
#' and collapse variables before calling non vectorized function calls.
#'
#' @export
#' @rdname scheduleTaskList
expandData = function(graph, dataLoadExpr)
{
    if(length(dataLoadExpr) == 0) return(graph)

    chunkLoadCode = lapply(dataLoadExpr, slot, "expr")

    mangledNames = Map(appendNumber, names(chunkLoadCode), chunkLoadCode)

    initialAssignments = mapply(initialAssignmentCode, mangledNames, chunkLoadCode, USE.NAMES = FALSE)

    vars = list(expanded = mangledNames
                , collapsed = list())

    oldcode = graph@code
    newcode = vector(mode = "list", length = length(oldcode))

    for(i in seq_along(oldcode)){
        expr = oldcode[[i]]
        tmp = expandCollapse(expr, vars)
        vars = tmp$vars
        newcode[[i]] = tmp$expr
    }
    newcode = c(initial_assignments, newcode)
    inferGraph(newcode)
}


appendNumber = function(varname, expr, sep = "_")
{
    # TODO: check that this name mangling scheme is not problematic.
    paste0(varname, sep, seq_along(expr))
}


# Generate code to do the initial assignment
initialAssignmentCode = function(varname, code)
{
    nm = lapply(varname, as.symbol)
    out = mapply(call, '=', nm, code, USE.NAMES = FALSE)
    as.expression(out)
}


expandCollapse = function(expr, vars)
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
#                collapseVector(expr, v)
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
            # Variable appears in the expression, which is a general function call.
            collapseVector(expr, vars)
        }
    } else {
        # No chunked variables appear, don't change it.
        list(vars = vars, expr = expr)
    }
}


expandVector = function(expr, vars)
{
    rhs = expr[[3]]
    function_name = as.character(rhs[[1]])
    if(!function_name %in% vectorfuncs){
        return(collapseVector(expr, vars))
    }

    function_args = as.character(rhs[-1])
    names_to_expand = intersect(names(vars), function_args)

    lhs = as.character(expr[[2]])

    # Record the lhs as now being an expanded variable
    # TODO: Check that the variables have the same number of chunks.
    first_one_var_names =  vars$expanded[names_to_expand[1]]
    vars$expanded[lhs] = appendNumber(lhs, first_one_var_names)

    names_to_expand = c(names_to_expand, lhs)

    newexpr = expandExpr(expr, vars$expanded[names_to_expand])

    list(vars = newvars, expr = newexpr)
}


# vars_to_expand is a list like list(a = c("a1", "a2"), b = c("b1", "b2"))
# This function then does the actual expansion from:
# b = f(a)
# to
# b1 = f(a1)
# b2 = f(a2)
expandExpr = function(expr, vars_to_expand)
{

    iterator = seq_along(vars_to_expand[[1]])

    # Initialize
    newexpr = lapply(iterator, function(...) expr)

    for(i in iterator){
        varname_lookup = lapply(vars_to_expand, function(var) as.symbol(var[i]))
        newexpr[[i]] = substitute_q(expr, varname_lookup)
    }
    newexpr
}


collapseVector = function(expr, vars)
{
    # If the variable has already been collapsed, then we don't need to do it again.

    list(vars = newvars, expr = newexpr)
}


collapseOneVariable = function(expr, var)
{
    # we already know it looks like:
    # y = f(x, z, ...)
    args
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

}


# TODO:
# - Make user extensible
# - Identify which arguments they are vectorized in
vectorfuncs = c("*")

# http://adv-r.had.co.nz/Computing-on-the-language.html#substitute
substitute_q <- function(x, env) {
      call <- substitute(substitute(y, env), list(y = x))
  eval(call)
}
