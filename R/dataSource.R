#' Constructor for ChunkDataFiles
#'
#' @export
ChunkDataFiles = function(files, sizes = file.info(files)$size
                          , readFuncName = inferReadFuncFromFile(files[1]), ...)
{
    new("ChunkDataFiles", files = files, sizes = sizes, readFuncName = readFuncName, ...)
}


#' Attempt to infer the type of a file.
inferReadFuncFromFile = function(fname)
{
    .NotYetImplemented()
}


#' @export
dataSource.expression = function(expr, ...)
{
    warning("Data source inference not yet implemented.")
    NoDataSource()
}


#' @export
`dataSource.<-` = function(expr, ...)
{
    callGeneric(rstatic::to_ast(expr), ...)
}


dataSource.Assign = function(expr, ...)
{
    lhs = expr$write$ssa_name
    callGeneric(expr$read, varName = lhs, ...)
}


dataSource.Call = function(expr, handlers = list(), ...)
{
    # The data inference depends on the function that was called.
    # So we can continue to dispatch, using the function name as the class.

    expr = rstatic::match_call(expr)
    fname = expr$fn$ssa_name
    m = match(fname, names(handlers))
    if(!is.na(m)){
        handlers[[m]](expr, handlers, ...)
    } else {
        func_class = paste0(fname, "_Call")
        class(expr) = c(func_class, class(expr))

        inferDataSourceFromCall(expr, ...)
    }
}


# Borrowing from http://adv-r.had.co.nz/Exceptions-Debugging.html#condition-handling
DataSourceNotFound = function(message = "Data source not found.", call = sys.call(-1))
{
    structure(
        class = c("DataSourceNotFound", "simpleError", "error", "condition"),
        list(message = message, call = call)
    )
}


#conditionMessage.DataSourceNotFound = 


#' @export
inferDataSourceFromCall.default = function(expr, ...)
{
    cond = DataSourceNotFound("No method yet implemented to infer a data source from this function call: ", utils::capture.output(rstatic::as_language(expr)))
    stop(cond)
}


inferDataSourceFromCall.read.table_Call = function(expr, ...)
{
    args = expr$args$contents

    # TODO: Fill these in.
    TextTableFiles(files = args$file$value
                   , ...)
}


inferDataSourceFromCall.read.fwf_Call = function(expr, ...)
{
    args = expr$args$contents

    # Taking the value of the arguments assumes they are string literal.
    # True after constant propagation.
    # It could also be something like list.files()
    # Or widths = c(10, 20), which is almost a string literal.
    # If we have all the resources then we could use that for constant propagation, and for evaluating and storing those simple objects where we actually have the values.
    # It's more appealing to me to do that all at once, as well as we can, early in the analysis, because then we can use it everywhere after.
    # Otherwise, we're handling all these same corner cases over and over again.

    # This is the same thing as identifying compile time constants.

    FixedWidthFiles(files = args$file$value
                    , widths = as.integer(args$widths$value)
                    , ...)
}


#' Find the first expression that we can infer a DataSource from
findFirstDataSource = function(expr, ...)
{
    ast = rstatic::to_ast(expr)
    for(i in seq_along(ast)){
        tryCatch({
            ds = dataSource(ast[[i]])
            return(list(DataSource = ds, location = i))
        }, DataSourceNotFound = function(e) NULL)
    }
    warning("Unable to infer the data source.")
    list(DataSource = NoDataSource(), location = NA)
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
# 
# #' @export
# #' @rdname dataSource
# setMethod("dataSource", signature(expr = "expression", args = "missing", varname = "ANY"),
# function(expr, args, varname, ...)
# {
#     dots = list(...)
# #    splitColumn = dots[["splitColumn"]]
# #    if(is.null(splitColumn)) splitColumn = as.character(NA)
# 
#     collector = dots[["collector"]]
#     if(is.null(collector)) collector = "c"
# 
#     varname = as.character(varname)
# 
#     ExprChunkData(expr = expr
# #                  , splitColumn = splitColumn
#                   , varname = varname
#                   , mangledNames = appendNumber(basename = varname, n = length(expr))
#                   , collector = collector
#                   , collected = FALSE
#                   , ...)
# })
# 
# 
# #' @export
# #' @rdname dataSource
# setMethod("dataSource", signature(expr = "character", args = "vector", varname = "ANY"),
# function(expr, args, varname, ...)
# {
#     func_name = expr
# 
#     # build up the calls to load every chunk
#     chunk_expr = lapply(args, function(args) do.call(call, list(func_name, args)))
#     # You know when you write `do.call(call` that you're in metaprogramming land!
# 
#     callGeneric(expr = as.expression(chunk_expr), varname = varname, ...)
# })
# 
# 
# #' @export
# tableChunkData = function(expr
#         , varname = "x"
#         , columns = character()
#         , splitColumn = character()
#         , mangledNames = appendNumber(basename = varname, n = length(expr))
#         , collected = FALSE
#         , collector = "rbind"
#         , addAssignments = TRUE
# ){
#     if(addAssignments){
#         expr = initialAssignmentCode(mangledNames, expr)
#     }
# 
#     TableChunkData(expr = expr
#         , varname = varname
#         , columns = columns
#         , splitColumn = splitColumn
#         , mangledNames = mangledNames
#         , collected = collected
#         , collector = collector
#         )
# }
# 
# 
# # Generate code to do the initial assignment
# initialAssignmentCode = function(mangledNames, code)
# {
#     nm = lapply(mangledNames, as.symbol)
#     out = mapply(call, '=', nm, code, USE.NAMES = FALSE)
#     as.expression(out)
# }
# 
# 
# #' Description of Data Files
# #'
# #' Contains information necessary to generate a call to read in these data files
# #'
# #' @export
# #' @param dir directory filled exclusively with data files
# #' @param files absolute paths to all the files
# #' @param sizes sizes of the objects in memory
# #' @param ... further details to help efficiently and correctly read in the data
# #' @return \linkS4class{DataFiles}
# dataFiles = function(dir
#     , files = list.files(dir, full.names = TRUE)
#     , sizes = sapply(files, function(f) file.info(f)$size)
#     , readFuncName = "read.csv", ...
#     )
# {
#     ChunkDataFiles(files = files, sizes = as.numeric(sizes), readFuncName = readFuncName)
# }


# In CodeAnalysis/explorations/findReadDataCalls Duncan returns the rstatic node of the individual calls that read the data.
# Begin copy:
############################################################
############################################################
