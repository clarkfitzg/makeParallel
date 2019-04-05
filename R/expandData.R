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

    mangledNames = Map(simpleNameMangler, names(chunkLoadCode), chunkLoadCode)

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


simpleNameMangler = function(varname, expr, sep = "_")
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

    list(vars = newvars, expr = newexpr)
}


if(FALSE){
    # developing, may move these to tests eventually

    dataLoadExpr = list(x = makeParallel:::ChunkDataSource(expr=parse(text = "1 + 2
              3 + 4")))

    expr = quote(y <- sin(x))

    find_var = makeParallel:::find_var

}


# TODO:
# - Make user extensible
# - Identify which arguments they are vectorized in
vectorfuncs = c("*")
