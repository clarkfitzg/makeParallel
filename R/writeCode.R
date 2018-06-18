setMethod("writeCode", c("GeneratedCode", "missing"), function(x, file, ...)
{
    x@code
})


setMethod("writeCode", c("GeneratedCode", "character"), function(x, file, ...)
{
    content = as.character(x@code)
    writeLines(content, file)
})
