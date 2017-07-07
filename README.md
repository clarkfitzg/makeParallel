# autoparallel

experimental library to make serial R code parallel

## Interactive use case

```{R}
library(autoparallel)

# Suppose docs is a large list of (XML) documents
docs = list(letters, letters, LETTERS)

do = parallelize(docs, workers = 2)
```

`parallelize` returns a closure that maintains server state. It evaluates expressions
much like `eval` and `parallel::clusterEvalq`.

```{R}
getfirst = function(doc) doc[1:5]

do(lapply(docs, getfirst))
```

The line above will do the equivalent of `lapply(docs, getfirst)`, but more
efficiently in parallel on the distributed data set. 

To implement later is when `getfirst()` or dependencies of `getfirst` change then
these should be exported to the cluster. First pass is to just export
the one function each time.
