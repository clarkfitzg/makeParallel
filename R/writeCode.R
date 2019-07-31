# Methods and functions associated with writing files.

#' @param overWrite logical write over existing file
#' @param prefix character prefix for generating file names
#' @export
#' @rdname writeCode
setMethod("writeCode", c("GeneratedCode", "logical"), 
    function(code, file, overWrite = FALSE, prefix = "gen_")
{
    oldname = file(schedule(code))
    fname = prefixFileName(oldname, prefix)
    if(file && !is.na(fname)){
        writeHelper(code, fname, overWrite = overWrite)
    }
    code@code
})


#' @export
#' @rdname writeCode
setMethod("writeCode", c("GeneratedCode", "missing"), function(code, file, ...)
{
    callGeneric(code, file = FALSE, ...)
})


#' @export
#' @rdname writeCode
setMethod("writeCode", c("GeneratedCode", "character"),
    function(code, file, overWrite = FALSE, ...)
{
    if(!is.na(file))
        writeHelper(code, file, overWrite = overWrite)
    code@code
})


#' @export
#' @rdname writeCode
setMethod("writeCode", c("expression", "character"),
    function(code, file, overWrite = FALSE, ...)
{
    writeHelper(fname = file, overWrite = overWrite, content = as.character(code))
})


writeHelper = function(code, fname, overWrite, content = as.character(code@code))
{
    if(file.exists(fname) && !overWrite){
        e = simpleError(sprintf("The file %s already exists. Pass overWrite = TRUE to replace %s with a new version.", fname, fname))
        class(e) = c("FileExistsError", class(e))
        stop(e)
    }
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
        # normalizePath needed here?
    } else as.character(NA)
    #} else NA
}


#' @export
#' @rdname file
setMethod("file", "TaskGraph", function(description)
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


#' Get File containing code
#'
#' @export
#' @rdname file
#' @param description object that may have a file associated with it
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

#' @export
#' @rdname fileSetter
setMethod("file<-", c("GeneratedCode", "character"), function(description, value)
{
    description@file = value
    description
})
