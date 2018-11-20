# Mon Nov 19 15:34:05 PST 2018

library(makeParallel)

g = inferGraph("vector_code.R")

# These are lists, so I can add more info in here.
g@graph$value

# I actually can't think of any others
lhsVectorFuncs = c("[")

# There are many, many more
rhsVectorFuncs = c("`<`", "`[`", "exp", "identity")

# I can also do this more rigorously by specifying which arguments a
# function is vectorized in and using `match.call`

# Various forms might make the code easier to manipulate.
# Here's a form that puts everything in terms of
# lhs = func(args)
# Assuming the code actually looks like this, or
# lhs[ss] = func(args)

code = list(lhs = lapply(g@code, `[[`, 2)
    , func = lapply(g@code, `[[`, c(3, 1))
    , args = lapply(g@code, function(e) as.list(e[[3]])[-1])
    )

code$vectorized = code$func %in% rhsVectorFuncs

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
