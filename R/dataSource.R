#' @export
#' @rdname dataSource
setMethod("dataSource", signature(expr = "expression", args = "missing"),
function(expr, args, ...)
{
    ChunkDataSource(expr = expr, ...)
})


#' @export
#' @rdname dataSource
setMethod("dataSource", signature(expr = "character", args = "vector"),
function(expr, args, ...)
{
    func_name = expr

    # build up the calls to load every chunk
    chunk_expr = lapply(args, function(args) do.call(call, func_name, args))

    ChunkDataSource(expr = as.expression(chunk_expr), ...)
})
