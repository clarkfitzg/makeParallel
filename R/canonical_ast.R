# 
canonical_ast = function(code)
{
    rstatic::to_ast(code)
    if(!is(ast, "Brace"))
        stop("AST has unexpected form.")
}
