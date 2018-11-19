# Mon Nov 19 15:34:05 PST 2018

library(makeParallel)

g = inferGraph("vector_code.R")

# These are lists, so I can add more info in here.
g@graph$value

vectorfuncs = c("<", "[", "exp")

# If the code was in this form I might be able to manipulate it more
# easily.


code = data.frame(lhs = 
