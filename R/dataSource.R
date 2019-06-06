#' @export
#' @rdname dataSource
setMethod("dataSource", signature(expr = "expression", args = "missing", varname = "ANY"),
function(expr, args, varname, ...)
{
    dots = list(...)
#    splitColumn = dots[["splitColumn"]]
#    if(is.null(splitColumn)) splitColumn = as.character(NA)

    collector = dots[["collector"]]
    if(is.null(collector)) collector = "c"

    varname = as.character(varname)

    ExprChunkData(expr = expr
#                  , splitColumn = splitColumn
                  , varname = varname
                  , mangledNames = appendNumber(basename = varname, n = length(expr))
                  , collector = collector
                  , collected = FALSE
                  , ...)
})


#' @export
#' @rdname dataSource
setMethod("dataSource", signature(expr = "character", args = "vector", varname = "ANY"),
function(expr, args, varname, ...)
{
    func_name = expr

    # build up the calls to load every chunk
    chunk_expr = lapply(args, function(args) do.call(call, list(func_name, args)))

    CallGeneric(expr = as.expression(chunk_expr), varname = varname, ...)
})


#' @export
tableChunkData = function(expr
        , varname = "x"
        , columns = character()
        , splitColumn = character()
        , mangledNames = appendNumber(basename = varname, n = length(expr))
        , collected = FALSE
        , collector = "rbind"
        , addAssignments = TRUE
){
    if(addAssignments){
        expr = initialAssignmentCode(mangledNames, expr)
    }

    TableChunkData(expr = expr
        , varname = varname
        , columns = columns
        , splitColumn = splitColumn
        , mangledNames = mangledNames
        , collected = collected
        , collector = collector
        )
}


# Generate code to do the initial assignment
initialAssignmentCode = function(mangledNames, code)
{
    nm = lapply(mangledNames, as.symbol)
    out = mapply(call, '=', nm, code, USE.NAMES = FALSE)
    as.expression(out)
}
