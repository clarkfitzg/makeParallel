#' @export
setMethod("writeCode", c("GeneratedCode", "NULL"), 
          function(x, file, overWrite = FALSE, prefix = "gen_", ...)
{
    srcfile = attr(x@schedule@graph@code, "srcfile")
    if(!is.null(srcfile)){
        file = prefixFileName(srcfile, prefix)
        writeHelper(x, file, overWrite = overWrite)
    }
})


#' @export
setMethod("writeCode", c("GeneratedCode", "character"),
        function(x, file, overWrite = FALSE, ...)
{
    writeHelper(x, file, overWrite = overWrite)
})


writeHelper = function(x, file, overWrite)
{
    if(file.exists(file) && !overWrite){
        message(sprintf("The file %s already exists. Pass overWrite = TRUE to replace %s with a new version.", file))
    }
    content = as.character(x@code)
    writeLines(content, file)
    message(sprintf("generated parallel code is in %s", file))
}


# Put the prefix in front of filename
prefixFileName = function(file, prefix)
{
        file.path(dirname(file), paste0(prefix, basename(file)))
}
