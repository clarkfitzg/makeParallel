## Notes

Working notes as I enhance the package.

------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------

Thu Apr  4 08:42:23 PDT 2019

I need to specify what the vectorized functions are, so that the scheduling step can break them up to operate on the chunks.
Here's the goal of what we want to do.

Original code:
```{r}
y = 2 * x
ym = median(y)
```

Side note:
We could use algebraic rules to show that this code, `ym = median(2 * x)` is equivalent to `ym = 2 * median(x)`.
The latter is more efficient.
But this kind of transformation has nothing to do with parallelism- it applies to any code, so it should be done in a more general package like `CodeAnalysis`.

Intermediate code, before scheduling:
```
x1 = readRDS("x1.rds")
x2 = readRDS("x2.rds")

y1 = 2 * x1
y2 = 2 * x2

y = c(y1, y2)
ym = median(y)
```

Here are rules that describe how every piece should come about.

```{r}
x1 = readRDS("x1.rds")
x2 = readRDS("x2.rds")
```
Insert anywhere before the first usage of `x`.
Mark `x` as a distributed object.

Side note: we could potentially 'unmark' `x` later if it's redefined.

------------------------------------------------------------

```{r}
y1 = 2 * x1
y2 = 2 * x2
```

`2 * x` is vectorized in both arguments.
Replace all vectorized function calls on a distributed object with the chunked versions, and mark the resulting object `y` as a distributed object.

------------------------------------------------------------

```{r}
y = c(y1, y2)
ym = median(y)
```

`median` is a general function with no defined reduce method, so we need to bring together the chunks of `y` before we can call it.

------------------------------------------------------------

I was thinking to subclass `DependGraph` to store the expanded code.
But I think it's more sane to have a function that just directly expands the code, because this will be fewer special cases to handle.


------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------

Wed Apr  3 10:20:45 PDT 2019

I think it's more clear conceptually for the `data` to be an argument to the scheduler.
The scheduler is the component that makes decisions about when and where to use the data.
It could be useful in the code analysis step when we try to follow the large data objects through the program.
But the scheduler can always do this kind of analysis that follows an object through the script, because it has the dependency graph and the code.

The scheduler _might_ change the code.
For example, it could break apart the big vectorized statements, or add calls to load the data.

------------------------------------------------------------

Something is bothering me about my data chunking scheme.
It's this- how am I going to insert the arguments into a generated script as code?

I could serialize the function arguments as R objects, save them alongside the written files, and then deserialize and call them when I need them.
Using functions in this way is more general than just assuming we have the full data loaded as R objects, because it allows computing the chunks as needed.
It would be better to store the arguments as literal code if possible, because that's easier to inspect.
I'll stick with the serialized objects for now because they're more general.

I recall dask has a pretty elegant way of doing this, with tuples and function calls.
 
There's an issue though- how can one run the code interactively after generating it?
Do they have to first write it out?
I guess that's not too much of a problem.

I should develop the use case for the list schedule, because that's the one I plan on developing more completely.
Probably the easiest way to do this is to insert the data loading steps into the source code and break up the vectorized statements.
This will allow me to use reuse the same list scheduler.

What is the core of what I need?
_Something_ that I can serialize and use to produce an R object.
Here are a few possible implementations:

- Evaluate an expression in an environment.
    Uses `eval`.
- Function with an environment and no arguments.
    Similar idea as a callback.
- Active binding.
    Like the callback, but different look.
- S expression like object.
    This is a list containing a function in the first position, and the arguments in the later positions.
    Same thing as dask

Let's think about the most sane way for the generated code to look:

```
# Before:
y = 2 * x

# After:
x1_env = load("x1_description.rds")
x1 = x1_env$compute()
x2_env = load("x2_description.rds")
x2 = x2_env$compute()

y1 = 2 * x1
y2 = 2 * x2

y = c(y1, y2)
```

This is going to turn into a big hairy mess.
Some issues that will come up:

- Propagating the times for the expressions
- Avoiding name conflicts

------------------------------------------------------------

Looking back over this, it seems like a faster way to start might be to just assume that we have an expression that will produce the chunk.
Then I can directly insert them, and not have to mess around with this loading and evaluating.
Indeed, the expression could just be a call to `source` or `load`.
