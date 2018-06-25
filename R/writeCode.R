# Methods and functions associated with writing files.

#' @export
setMethod("writeCode", c("GeneratedCode", "logical"), 
    function(x, file, overWrite = FALSE, prefix = "gen_", ...)
{
    #srcfile = attr(x@schedule@graph@code, "srcfile")
    srcfile = file(schedule(x))
    if(file && !is.na(srcfile)){
        fname = prefixFileName(srcfile, prefix)
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


# TODO:* Define and use a file method here.

writeHelper = function(x, file, overWrite)
{
    if(file.exists(file) && !overWrite){
        e = simpleError(sprintf("The file %s already exists. Pass overWrite = TRUE to replace %s with a new version.", file, file))
        class(e) = c("FileExistsError", class(e))
        stop(e)
    }
    content = as.character(x@code)
    writeLines(content, file)
    message(sprintf("generated parallel code is in %s", file))
    file
}


# Put the prefix in front of filename
prefixFileName = function(file, prefix)
{
    newname = paste0(prefix, basename(file))
    dir = dirname(file)
    if(dir == ".") newname else file.path(dir, newname)
}


setMethod("file", "DependGraph", function(description)
{
    srcfile = attr(description@code, "srcfile")
    out = if(is.null(srcfile)) NA else srcfile$filename
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


setMethod("file<-", c("GeneratedCode", "LogicalOrCharacter"), function(description, value)
{
    description@file = value
    description
})
