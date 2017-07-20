
x + 1

function() 1



e = quote(apply(x, mean))

sub_one_eval(e, list(apply = as.name("mclapply")))

f1 = quote(function() 1)

f2 = sub_one_eval(quote(function() 1), list(apply = as.name("mclapply")))

caller = function() sub_one_eval(function() 1, list(apply = as.name("mclapply")))

caller = function(f) sub_one_eval(f, list(apply = as.name("mclapply")))

sub_one_docall(e, list(apply = as.name("mclapply")))


# TODO: tests to clarify what and how this should work
sub_one = sub_one_eval


