#' @export
#' @rdname dataSource
setMethod("dataSource", signature(expr = "expression", args = "missing"),
function(expr, args, ...)
{
    ExprChunkData(expr = expr, ...)
})


#' @export
#' @rdname dataSource
setMethod("dataSource", signature(expr = "character", args = "vector"),
function(expr, args, ...)
{
    func_name = expr

    # build up the calls to load every chunk
    chunk_expr = lapply(args, function(args) do.call(call, list(func_name, args)))

    ExprChunkData(expr = as.expression(chunk_expr), ...)
})
