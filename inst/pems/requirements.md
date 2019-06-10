# Requirements

What does the code analysis step need to infer for the PEMS example?

- Which columns are necessary for the code to run.
    This allows the code generator to only read in those columns that it needs, which saves memory and time.
- The GROUP BY / `split` pattern in the code.
    Why does this matter?
    If the user tells `makeParallel` that the data is already indexed with respect to the same grouping column, then the scheduler does not need to split the data.
    If the user specifies the distribution of the groups across files, then the scheduler can potentially assign groups to workers in ways that minimize data movement.
    If the user merely tells `makeParallel` that the whole data is too large to fit in memory, but the chunks will all fit in memory, then the scheduler can efficiently do the grouping.

Partial evaluation and standardizing code are really just implementation details, that is, how we make these things work.
