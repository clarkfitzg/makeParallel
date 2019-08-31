# Sat Aug 17 08:06:35 PDT 2019
# In CodeAnalysis/explorations/findReadDataCalls Duncan returns the rstatic node of the individual calls that read the data.


#' Infer Data Source Object From Code
#'
#' @param expr expression to find the data source in
#' @value \linkS4class{DataSource} object 
inferDataSource = function(expr)
{
    warning("Data source inference not yet implemented. Data source should be specified.")
    NoDataSource()
}


# Given a single call that loads data, return a DataSource object.

#' @export
#' @rdname dataSource
#setMethod("dataSource", signature(expr = "call", args = "missing", varname = "ANY"),
#function(expr, args, varname, ...)
#{
#    fun_name = as.character(expr[[1]])
#
#    # TODO: Use switch() or method dispatch to get the right kind of object.
#    if(fun_name == "read.fwf"){
#    }
#})


# Old stuff below this line, I will probably rewrite.
############################################################

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
    # You know when you write `do.call(call` that you're in metaprogramming land!

    callGeneric(expr = as.expression(chunk_expr), varname = varname, ...)
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


#' Description of Data Files
#'
#' Contains information necessary to generate a call to read in these data files
#'
#' @export
#' @param dir directory filled exclusively with data files
#' @param files absolute paths to all the files
#' @param sizes sizes of the objects in memory
#' @param ... further details to help efficiently and correctly read in the data
#' @return \linkS4class{DataFiles}
dataFiles = function(dir
    , files = list.files(dir, full.names = TRUE)
    , sizes = sapply(files, function(f) file.info(f)$size)
    , readFuncName = "read.csv", ...
    )
{
    ChunkDataFiles(files = files, sizes = as.numeric(sizes), readFuncName = readFuncName)
}
