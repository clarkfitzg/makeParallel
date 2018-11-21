# Mon Nov 19 15:34:05 PST 2018

library(makeParallel)

g = inferGraph("vector_code.R")

# These are lists, so I can add more info in here.
g@graph$value

# I actually can't think of any others
lhsVectorFuncs = c("[")

# There are many, many more
rhsVectorFuncs = c("`<`", "`[`", "exp")

loadFuncs = c("load")
saveFuncs = c("save")

types = data.frame(name = c(rhsVectorFuncs, loadFuncs, saveFuncs)
    , type = c(rep("vector", length(rhsVectorFuncs))
                 , rep("load", length(loadFuncs))
                 , rep("save", length(saveFuncs))
                 )
    , stringsAsFactors = FALSE)

# Classify a function into one of several possible types.
# I will need to do this more rigorously by specifying which arguments a
# function is vectorized in and using `match.call`
funcType = function(funcName, funcTypeTable, fallbackType = "general")
{
    funcName = as.character(funcName)
    index = match(funcName, funcTypeTable$name)
    if(is.na(index)) fallbackType 
        else funcTypeTable[index, "type"]
}

# Various forms might make the code easier to manipulate.
# Here's a form that puts everything in terms of
# lhs = func(args)
# Assuming the code actually looks like this, or
# lhs[ss] = func(args)

code = list(lhs = lapply(g@code, `[[`, 2)
    , func = lapply(g@code, `[[`, c(3, 1))
    , args = lapply(g@code, function(e) as.list(e[[3]])[-1])
    )

code$funcType = sapply(code$func, funcType, funcTypeTable = types)

# Now we can fuse the vectorized functions based on the graph structure.
# What exactly does this mean?
# That we'll run all the parts in parallel that we possibly can before we
# hit a general function call that forces us to collect the results from
# the workers.
# I think this means starting at a node, first the root in the graph, and
# identifying all the children with vectorized functions that can run
# before hitting a node with a general function call that forces you to
# stop. 

# To run, first run all the child nodes on each of the data chunks which
# are distributed among the workers. Then have all the workers return their
# part of the result to the manager process to evaluate the general
# function call. Then we still have the data loaded on all the workers, so
# we can continue to run the remainder of the program in this fork - join
# manner, leaving as much of the data distributed as possible.

# This only really operates on one single object or table at a time.

# Alternatively we can do something simpler and more dynamic, closer to the
# way that R typically operates:
# Evaluate each statement either in serial on the manager or in parallel on
# the object distributed among the workers. Then we need to maintain a list
# of what objects are distributed. For example, we start knowing that `x` is
# distributed, and then we run:
#       cond = x < 0
# so we know that `cond` is also distributed, because it's the result of a
# vectorized function call on `x`.

# This relates to something I did years ago, and that foreach and futures
# also do- check which variables are needed and possibly export them.

# If the data fits in memory then these two approaches are pretty similar.
# The latter will have more overhead because it communicates at every
# vectorized statement. The code analysis and fusion approach becomes
# appealing when we apply it to a data set that's larger than memory,
# because it minimizes the number of passes that we have to make through
# the data. Extending to include the reduce will also help with the 2nd
# case.


