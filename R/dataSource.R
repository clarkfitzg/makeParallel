# Sat Aug 17 08:06:35 PDT 2019

# In CodeAnalysis/explorations/findReadDataCalls Duncan returns the rstatic node of the individual calls that read the data.
# Begin copy:
############################################################
isReadFun =
function(x, readFuns)
    (is(x, "Call") && x$fn$ssa_name %in% readFuns) ||
       is(x, "Symbol") && x$value %in% readFuns && !(is(x$parent, "Call") && identical(x$parent$fn, x))

findReadDataCalls =
    #
    # Need to handle
    #  f = read.csv
    #  f(file)
    #
    #
function(code, readFuns = getReadFunNames(), recursive = TRUE)
{
    code1 = to_ast(code)

    if(is(code1, "Function")) {
        # Find all the calls or references to anything in readFuns
        idx = find_nodes(code1, isReadFun, readFuns)
        return(code1[idx])
    } else
        # look only at the top-level expressions in the script that do some calculation and  not the Function defintions.
       exprs = getTopLevelCalls(code1)

     # need to worry about the order here as the alias can come into effect after being called
    aliases = findAliases(exprs)    
    w = aliases %in% readFuns
    if(any(w))
        readFuns = c(readFuns, names(aliases)[w])

    if(recursive) {
         # So look at functions defined in the script.
         # We automatically go down top-level expressions except function definitions.
        funs = getDefinedFuns(code)
        w = sapply(funs, function(f)
                             findReadDataCalls(f, readFuns))
        w2 = sapply(w, length) > 0
        readFuns = c(readFuns, names(funs)[w2])
    }


  ans =  lapply(exprs, function(e) {
                           idx = find_nodes(e, isReadFun, readFuns)
                            ans = list()
                            if(isReadFun(e, readFuns))
                               ans[[1]] = e
      
                            if(length(idx))
                               append(ans, lapply(idx, function(i) e[[i]]))
                            else
                               ans
                       })

    ans = unlist(ans, recursive = FALSE)
    ans = unique(lapply(ans, function(x) if(is(x, "Symbol")) {p = x$parent; if(is(p, "ArgumentList")) p = p$parent; p} else x))
    return(ans)
    
if(FALSE) {    
    els = lapply(idx, function(i) code1[[i]])
    w = sapply(els, isReadDataCall, readFuns)
    els[w]
}    
    
#    w = sapply(code1[idx], isReadDataCall)
#    code1[idx][w]
}


getTopLevelCalls =
    # exclude function definitions
function(code)
{
    k = children(code)
    w = sapply(k, function(x) !(is(x, "Assign") && is(x$read, "Function")))
    k[w]
}
    

isReadDataCall =
    #
    #
    #
function(call, readFuns = getReadFunNames())
{
  call$fn$ssa_name %in% readFuns
}




getReadFunNames =
function(..., .names = ReadFunNames)
{
  c(unlist(list(...)), .names)
}

ReadFunNames = c(
    "readLines",
    "scan",
    "read.csv",
    "read.csv2",    
    "read.table",
    "read.delim",
    "read.delim2",
    "read.fwf",
    "count.fields"
    )


getDefinedFuns =
function(code)
{
    isFun = find_nodes(code, function(x) is(x, "Assign") && is(x$read, "Function"))
    els = lapply(isFun, function(i) code[[i]])
    structure(lapply(els, function(x) x$read), names = sapply(els, function(x) x$write$ssa_name))
#    structure(lapply(code[isFun], function(x) x$read), names = sapply(code[isFun], function(x) x$write$ssa_name))
}


findAliases =
function(code)
{
    isFun = find_nodes(code, function(x) is(x, "Assign") && is(x$read, "Symbol"))
    els = lapply(isFun, function(i) code[[i]])
    structure(sapply(els, function(x) x$read$value), names = sapply(els, function(x) x$write$ssa_name))
#    structure(lapply(code[isFun], function(x) x$read), names = sapply(code[isFun], function(x) x$write$ssa_name))
}

############################################################



#' Infer Data Source Object From Code
#'
#' @param expr expression to find the data source in
#' @return \linkS4class{DataSource} object 
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
