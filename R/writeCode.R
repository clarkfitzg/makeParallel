# Methods and functions associated with writing files.

#' @export
#' @rdname writeCode
setMethod("writeCode", c("GeneratedCode", "logical"), 
    function(x, file, overWrite = FALSE, prefix = "gen_", ...)
{
    oldname = file(schedule(x))
    fname = prefixFileName(oldname, prefix)
    if(file && !is.na(fname)){
        writeHelper(x, fname, overWrite = overWrite)
    }
    x@code
})


#' @export
#' @rdname writeCode
setMethod("writeCode", c("GeneratedCode", "missing"), function(x, file, ...)
{
    callGeneric(x, file = TRUE, ...)
})


#' @export
#' @rdname writeCode
setMethod("writeCode", c("GeneratedCode", "character"),
    function(x, file, overWrite = FALSE, ...)
{
    if(!is.na(file))
        writeHelper(x, file, overWrite = overWrite)
    x@code
})


writeHelper = function(x, fname, overWrite)
{
    if(file.exists(fname) && !overWrite){
        e = simpleError(sprintf("The file %s already exists. Pass overWrite = TRUE to replace %s with a new version.", fname, fname))
        class(e) = c("FileExistsError", class(e))
        stop(e)
    }
    content = as.character(x@code)
    writeLines(content, fname)
    message(sprintf("generated parallel code is in %s", fname))
    fname
}


# Extract the original file name from the schedule and prefix it.
prefixFileName = function(oldname, prefix)
{
    if(!is.na(oldname)){
        newname = paste0(prefix, basename(oldname))
        dir = dirname(oldname)
        if(dir == ".") newname else file.path(dir, newname)
    } else as.character(NA)
    #} else NA
}


#' @export
#' @rdname file
setMethod("file", "DependGraph", function(description)
{
    srcfile = attr(description@code, "srcfile")

    # Interactively using parse(text = "...") names the file "<text>". We
    # don't want this name. So this function will fail is someone actually
    # has an R script named "<text>".

    if(is.environment(srcfile)){
        out = srcfile$filename
        if(out == "<text>")
            out = NA
    } else {
        out = NA
    }

    as.character(out)
})


#' @export
#' @rdname file
setMethod("file", "Schedule", function(description)
{
    callGeneric(description@graph)
})


#' @export
#' @rdname file
setMethod("file", "GeneratedCode", function(description)
{
    description@file
})


#setMethod("file<-", c("GeneratedCode", "LogicalOrCharacter"), function(description, value)

#' Set file
#'
#' @export
#' @rdname file
#' @param description \linkS4Class{GeneratedCode} (matches signature for
#' \code{\link[base]{file}})
#' @param value file name to associate with object
setMethod("file<-", c("GeneratedCode", "character"), function(description, value)
{
    description@file = value
    description
})
