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
Veterans Administration (VA) Court appeals are one such example. Each file
contains the summary of a court case. 
One can download a handful from the VA servers as follows:

```{R}

datadir = "~/data/vets/appeals_sample"

fnames = paste0("1719", 100:266, ".txt")
urls = paste0("https://www.va.gov/vetapp17/files3/", fnames)

Map(download.file, urls, paste0(datadir, fnames))

```

The file names themselves are small, so we can cheaply distribute them
among the parallel workers.

```{R}

filenames = list.files(datadir, full.names = TRUE)
length(filenames)

do = parallelize(filenames)

```

The following code actually loads the data contained in the files and
assigns the result into `appeals` on the cluster. 

```{R}

do({
    appeals <- lapply(filenames, readLines)
    appeals <- sapply(appeals, paste, collapse = "\n")
    appeals <- enc2utf8(appeals)
    NULL
})

```

The braces along with the final `NULL` are necessary to avoid transferring
the large data set from the workers back to the manager.

The code above only assigned `appeals` to the global environment of the
workers. It does not exist in the manager process.

```{R}

# FALSE
"appeals" %in% ls()

```

The parallel evaluator allows us to compute on it with the same code that
can be used for serial R.

```{R}

do(length(appeals))
do(class(appeals))

```

We may want to look more closely at those cases which have been remanded
for further evidence. If they're a reasonably small subset we may choose to
bring them back into the manager process for further non parallel analysis.
This would be useful to see the warnings that may come from our code, for example.

```{R}

# Check how many we're about to bring back
do(sum(grepl("REMAND", appeals)))

# Bring them back from the workers
remand <- do(appeals[grepl("REMAND", appeals)])

length(remand)

```

In summary, when working with larger data sets it's efficient to minimize
the data movement. We avoided it in this case by only distributing the
relatively small vector of file names and having each worker independently
load the files that it needed, thus keeping the data in place on that
worker.

## Cleaning up

When finished it's a good idea to shut down the cluster.
The cluster is available as an attribute on the parallel evaluator object.

```{R}

parallel::stopCluster(attr(do, "cluster"))

```
