# makeParallel

This package will soon be available on CRAN. Install it with

```{r}
install.packages("makeParallel")
```

This is a package in R to take general R code and transform it into
parallel code. General R code means code that just uses functions in base
R, no additional packages.

This differs from most approaches to parallel programming in R. Most
conventional approaches define a certain API that the user then defines
their program around. The problem with this is that then this code becomes
tied to the package, so one has to write code in different ways.

The appeal of this approach is that you don't have to change your code in
any way. By allowing this _system_ to change your code you can benefit from
underlying improvements in the system, and change your code in ways that
you may have never thought of, or that were manually infeasible.


## Technique

Code transformation relies on static code analysis. This means we don't
actually run any code until the user specifically asks for it.
The [CodeDepends package](https://github.com/duncantl/CodeDepends)
currently provides many underlying tools.

As we build more tools that are useful for general purpose static R code
analyis we've been putting them in the [CodeAnalysis
package](https://github.com/duncantl/CodeAnalysis) which this package will
eventually come to depend on.

## Future

We're currently working on extending makeParallel to take into account the
size and nature of the data to be analyzed. For example, if the data won't
fit into memory then this typically a totally different approach to reading
the data and performing the computations.
