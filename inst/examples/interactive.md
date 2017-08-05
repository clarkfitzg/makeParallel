Fri Aug  4 16:26:05 PDT 2017

This example is to show how one can use `autoparallel` for interactive use.

We'll start with a basic example.

```{R}

library(autoparallel)

x = list(1:10, letters, LETTERS)

do = parallelize(x)
do

```

The parallel evaluator named `do` splits `x` into approximately equal parts
so that one can run code in parallel.

```{R}

lapply(x, head)

do(lapply(x, head))

```

Calling the same code through `do` produces the same result as the base R
case. Under the hood `do` sent the code to different R processes for
evaluation. 

This is meant for interactively building functions and analysis on large
data sets. The interactive feature is sending functions from one's global
workspace to the parallel workers. We can see the results of the improved /
debugged version of the function as we work on them.

```{R}

# An analysis function
myfun = function(x) x[1:2]

do(lapply(x, myfun))

# Oops I actually need the first 4
myfun = function(x) x[1:4]

# Now we see the new results of myfun
do(lapply(x, myfun))

```

## Working with many files

A realistic example is working with many files simultaneously. The US
Veterans Administration Court
appeals are one such example. Each file contains the summary of a court
case. 

The file names themselves are small, so we can cheaply distribute them
among the parallel workers.

```{R}

filenames = list.files("/home/clark/data/vets/appeals/", full.names = TRUE)
length(filenames)

do = parallelize(filenames)

# I know ahead of time each file is less than 1 MB
MAXCHAR = 1e6

# TODO: export this variable
do(appeals <- sapply(filenames, readChar, nchars = MAXCHAR))

```
