# Methods and functions associated with writing files.

#' @export
setMethod("writeCode", c("GeneratedCode", "logical"), 
    function(x, file, overWrite = FALSE, prefix = "gen_", ...)
{
    oldname = file(schedule)
    fname = prefixFileName(oldname, prefix)
    if(file && !is.na(fname)){
        writeHelper(x, fname, overWrite = overWrite)
    }
    x@code
})


#' @export
setMethod("writeCode", c("GeneratedCode", "missing"), function(x, file, ...)
{
    callGeneric(x, file = TRUE, ...)
})


#' @export
setMethod("writeCode", c("GeneratedCode", "character"),
    function(x, file, overWrite = FALSE, ...)
{
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
    if(!is.null(oldname)){
        newname = paste0(prefix, basename(oldname))
        dir = dirname(oldname)
        if(dir == ".") newname else file.path(dir, newname)
    #} else as.character(NA)
    } else NA
}


setMethod("file", "DependGraph", function(description)
{
    srcfile = attr(description@code, "srcfile")
    out = if(is.null(srcfile)) NA else srcfile$filename
    # This is what parse(text = "...") returns.
    # It will fail is someone actually has an R script named "<text>".
    if(out == "<text>")
        out = NA
    as.character(out)
})


setMethod("file", "Schedule", function(description)
{
    callGeneric(description@graph)
})


setMethod("file", "GeneratedCode", function(description)
{
    description@file
})


#setMethod("file<-", c("GeneratedCode", "LogicalOrCharacter"), function(description, value)
setMethod("file<-", c("GeneratedCode", "character"), function(description, value)
{
    description@file = value
    description
})
