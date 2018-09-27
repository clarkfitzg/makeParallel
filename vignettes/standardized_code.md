## Standardized Code

A couple things are becoming clear to me:

1. We need to preserve the code as it comes into the function, since we infer everything from this original code.
2. It's often easier to do the scheduling on modified code.

Therefore it would be useful to have two versions of the code- one original, and one modified.
Nick and I have spoke about this before: putting the code in 'canonical form'.
I'll call it 'standardized code', so I can use a more common word.

The main thing I want right now from the standardized code is to group plotting edges.
We could also change `for` loops -> `lapply` at this step.
In the future I could see wanting more, for example:

- break down to subexpressions, and schedule those individually
- transform the magrittr pipe, `%>%`, into regular looking calls
- single static asssignment

It should be the responsibility of makeParallel to standardize the code.
Otherwise, we would require the user to write their code according to our model, which is exactly what we don't want.
Also, if the package dictates how we standardize then we can continue to modify how we standardize it- it doesn't have to be fixed or concretely specified.

All of these things will require us to change the timing information.

For scheduling we only need the standardized code, and the graph that comes from the standardized code.

The new model then would transform in these steps:

- User code
- Standardized code
- Dependency graph (with only use-def edges)
- Schedule
- Generated code

We may use some form of dependency graph on the user code to help standardize it, but this is really just an implementation detail.
The scheduler needs to consume a dependency graph with only use-def edges, because this helps the steps to be modular.
Each scheduler doesn't need to handle arbitrary types of edges.
What we can do is 'collapse' all edges which are not use-def edges down into blocks.
This collapsing step can do all the changes to the timings.

I may be overthinking it with the standardized code.
How much transparency do we need for each step?
