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

```{R}

do(lapply(x, head), simplify = FALSE)

```


