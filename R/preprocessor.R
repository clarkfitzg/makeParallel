# Apply preprocessing steps to code
preprocess = function(code)
{
    for(i in seq_along(code)){
        if(class(code[[i]]) == "for"){
            code[[i]] = forloop_to_mclapply(code[[i]]) 
        }
    }
    code
}
