match_call_if_possible = function(node){
    tryCatch(rstatic::match_call(node)
             , error = function(e) node)
}


canonical_ast = function(code)
{
    ast = rstatic::to_ast(code)
    if(!is(ast, "Brace")){
        b = rstatic::Brace$new()
        b$contents = ast
        ast = b
    }
    rstatic::replace_nodes(ast, match_call_if_possible)
    ast
}
