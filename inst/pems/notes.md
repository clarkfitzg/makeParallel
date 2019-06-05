## Summary

For meeting Duncan and Nick on 30 May.

Since we last met two weeks ago I've been working on getting the software (makeParallel) to the point where the PEMS example runs completely.
This means I can just call `makeParallel("pems.R", data = d, platform = p)`, where `pems.R` is a file with R code, and `d` and `p` are the data and platform descriptions provided by the user.
I've made progress in adding `data` and `platform` into the model.
Before I was only dealing with the code.

Right now I'm doing a series of actual code transformations, from R code to R code.
It's nice to stay with R expressions, because then we can always run it.
The approach is to implement whatever analysis or transformation I want to do for one 'standard' representation of the code.
If the code is not written in that standard way then I'll try to transform it so that it is.

For example, I'm interested in detecting splits based on one column of a data frame.
All of the following will produce the same split, and are detectable with static analysis:
```{r}
s1 = split(data, data$column)

s2 = split(data, data[, "column"])

s3 = split(data, data[["column"]])

dc = data[, "column"]
s4 = split(data, dc)
```
For this approach I would convert all of these to whichever form I found most convenient, and then call that the "standard form" and write the analysis to handle that particular form.
It's not necessarily straightforward how to transform all of these into the same form, because these they may span multiple lines, as in the last example.

Ideally this form is the same for all code analysis.
But it could happen that different forms work better for different purposes.


### Challenges

Nested subexpressions are becoming a problem because they require a bunch of code to deal with special cases - everything is a special case.
For example, to detect which columns in a data frame `data` are used I looked for a call of the form: `data[, c("col1", "col2", ..., "colk")]`, that is, subsetting `data` where the column selection is a call to `c` with string literals.
How did I handle this case before when I detected column usage in CodeAnalysis?
I just evaluated the arguments that would go in the place of a column name.
I'm not sure if I handled the case when they're logicals.
The version I have here is much more conservative.

Later, when I go to expand `[` as a vectorized function, it would be better if this was instead two calls:
```{r}
tmp1 = c("col1", "col2", ..., "colk")
data[, tmp1]
```
This is better because it simplifies the logic required to expand vectorized functions.
It also exposes more parallelism.

Here's the issue: there are two things going on here- expanding vectorized statements, and using the task graph to rewrite the code for eager evaluation of subexpressions.
Handling both of them simultaneously is complicated, when instead they could be handled separately.
If we rewrite the code for eager evaluation, then we make new but equivalent R code that includes the variable names which we will actually need if we generate task parallel code on sub expressions.
It's still R code, it's just simpler.
The task graph becomes simpler too, because all R objects that are nodes and are subexpressions will have a symbol associated with them- there won't be any more anonymous nodes representing nested subexpressions.
If we can't unnest a subexpression because of lazy evaluation, then it becomes part of its parent expression.
Maybe the intermediate forms that we put the code into are an implementation detail, but they are important ones.




## Tasks

Goal: get the PEMS example fully working.
This means to the point where I can just call `makeParallel("pems.R", data = dd, workers = 10L)`, where `dd` is a data description written by the user.

All of the semantics of the program should be contained within `pems.R`.
One exception is the data reading code, since we'll generate that.

The first priority is to get the version working that handles data that's already split in the files.

- handle `split(data, data_column)` as a special case when `data` is a chunked object that is split based on the values of `data_column`.
    This means we must capture and propagate the semantics of `data_column = data[, "column"]`.
- partial evaluation mechanism for string literals of the form `tmp1 = c("station", "flow2", "occupancy2")`.
- X add `[`, `lapply` to list of vectorized functions.
- X expand the code into one statement per group based on the data description.
- X generate calls that read in the data and do column selection at the source.
- X determine which columns in a data frame are used (code analysis).
- X implement data description.
    This should include the values of the column to GROUP BY, along with counts.

Second priorities:

- recursively detect function calls that are used, so we can ship all the necessary functions to the workers (code analysis)
- implement re-grouping operation, aka shuffle.
- remove variables after we are done using them.
- Transform the code 
```{r}
# Before:
pems = pems[, c("station", "flow2", "occupancy2")]

# After
tmp1 = c("station", "flow2", "occupancy2")
pems = pems[, tmp1]
```
This will make the call to `[` simple.



## Data Description 1

Describing a data source
Needs to express that the files are split based on the station ID

Mandatory arguments

- fun: The first argument is the name of a function
  	Another way of doing this is to say that it's a delimited text file, and then pick the function.
- args: Vector of arguments for the first argument.
      Calling fun(args[[i]]) loads the ith chunk.
- class: Class of the resulting object.
      We can support common ones like vectors and data frames, and potentially allow user defined ones here too.

Optional arguments

- splitColumn: Name of a column that defines the chunks.
      Here it means that each chunk will have all the values in the data with one particular value of the column.
  	This tells us if the data are already organized for a particular GROUP BY computation.
- columns: named vector with columns and classes of the table
- colClasses: Classes of the columns (see read.table)

```{r}
pems_ds = dataSource("read.csv", args = list.files("stationID"), class = "data.frame", splitColumn = "station",
	columns = c(timeperiod = "character", station = "integer"
		, flow1 = "integer", occupancy1 = "numeric", speed1 = "numeric"
		, flow2 = "integer", occupancy2 = "numeric", speed2 = "numeric"
		, flow3 = "integer", occupancy3 = "numeric", speed3 = "numeric"
		, flow4 = "integer", occupancy4 = "numeric", speed4 = "numeric"
		, flow5 = "integer", occupancy5 = "numeric", speed5 = "numeric"
		, flow6 = "integer", occupancy6 = "numeric", speed6 = "numeric"
		, flow7 = "integer", occupancy7 = "numeric", speed7 = "numeric"
		, flow8 = "integer", occupancy8 = "numeric", speed8 = "numeric"
	)
)
```

Hmmm, this approach above does not give me enough information to do the `cut` trick to select columns.
Furthermore, it's completely tied to R because we're building up R expressions rather than describing how the data is laid out.
The improved version is in `transform.R`.


## detecting the GROUP BY

We need to find the GROUP BY particularly when the data is split into groups.
When will we do this?
It ought to happen before the scheduling, since many different scheduling algorithms can potentially take advantage of expanded code.
I'm also leaning towards scheduling algorithms that are based at looking at all the fine grained statements.

In this case the statement expansion should even come before the graph inference, because the graph will change when the code is expanded.


## Expand Code

We need a general way to expand code.
One way is to dispatch on the class of the data description.
Then when we see the data comes from `dataFiles`, we know how to generate the right expressions to load these.

I do need to start bringing in platform information now.
If we have a POSIX machine then we can use the `cut` trick with `pipe`.
If we have the data.table package we can select the columns at read.
Otherwise we will have to read using the functions in base R.
I was imagining that we only need the platform information in the end when we finallly generate the code, but in this case we're partially generating code as we go, so we need the information earlier.


## Order of expansion

How exactly will we expand all the code?
What steps are there in the process?
Given the data description, the variable name, and the columns used, we can generate the data loading code.
Then we still need to know how to expand these lines:

```{r}
pems2 = split(pems, pems$station)
results = lapply(pems2, npbin)
results = do.call(rbind, results)
```

Essentially the split goes away because of the structure of the data chunks, so we bypass creating the `pems` object and instead just go directly to the `pems2` object.
An alternative way to think about it is that `pems` and `pems2` are the same thing, but `pems2` has some indexing structure imposed on it.

Thinking about doing this as a series of steps now- the next step is to split apart the `lapply` given some mangled names, and then bring the chunks back together before the general function, the `do.call`.
This is again the same concept as `expandData`, which suggests an approach where I have a list of expanded variables with the same chunking scheme, and walk over the code, expanding each variable as I go.
Let's try and describe this a little more precisely.

_The following summarizes what I have in `tex/expand_vectorized.tex` in my dissertation repository._

Start with a named list, where the names correspond to variable names, and the values are the mangled names.
The data description identifies the variable names, so it can populate the list.
For simplicity at the moment, let's just suppose everything is chunked in the same way.
We walk over the code, one statement at a time.
If that statement uses any variable in a vectorized function call, then we expand it.
If it assigns the result to a new variable then that new variable is now expanded.
If that statement uses the variable in a general function call, then we collapse it.
If that statement uses the variable in a reducible function call, then we insert the reduce code to gather up one of the reduced objects.
I've implemented everything except the reduce in the original `expandData` code.

I'm tempted to switch back to analyzing the `tapply` or `by`, but I shouldn't do this, because the `split` followed by `lapply` is more general, since it allows multiple operations on the split data.
That is, we can easily convert all `tapply` or `by` calls into a `split` followed by `lapply`, and this is more like the code that we'll generate anyways.

-----------------------------------------------------------------

How will the object oriented structure be set up?
We can call `expandData` recursively, and I think this may lead to a more elegant design.
`expandData` is our general purpose function that takes (code, data, platform), and produces new code.
The scheduler takes this new code and arranges it in an efficient way on the workers.

If this is the case then `expandData` needs to keep track of where it is in the code, when and where to insert new statements.

-----------------------------------------------------------------

I'm struggling with nested expressions as I go to implement this.
We need to go 


## Progress

Here's where I'm at.
The data loading calls are there.

```{r}
# It's more convenient at the moment for me to use the varname in the object.
out = makeParallel("pems.R", data = d, platform = p, scheduler = scheduleTaskList)

# Could use a more convenient way to extract this code
tcode = schedule(out)@graph@code

> tcode[-c(3,4)]
# It generated this code:

pems_1 = pipe("cut -d , -f station,flow2,occupancy2 stationID/313368.csv")
pems_2 = pipe("cut -d , -f station,flow2,occupancy2 stationID/313369.csv")
pems = pems[, c("station", "flow2", "occupancy2")]
pems2 = split(pems, pems$station)
results = lapply(pems2, npbin)
results = do.call(rbind, results)
write.csv(results, "results.csv"))
```

Our focus is on these lines:

```{r}
pems = pems[, c("station", "flow2", "occupancy2")]
pems2 = split(pems, pems$station)
results = lapply(pems2, npbin)
```

They should become:

```{r}
results_313368 = npbin(pems_313368)
results_313369 = npbin(pems_313369)
 
results = list(results_313368, results_313369)
```

What logic needs to be in place for this to happen?

This line can be dropped when we check `columnsUsed`.
```{r}
pems = pems[, c("station", "flow2", "occupancy2")]
```
Why?
When is it valid to drop such a line?
The case we're in here is that it's the first line to use the `pems` variable of interest, and it redefines `pems` based on the column selection, so we can leave it out if we do the column selection at the source.
This seems a little specific.
To generalize it we would have to use the concept of _column selection at source_ in more places.

Alternatively, we could consider `[` to be a vectorized function, since it is.
Then the line in question would become:
```{r}
pems_1 = pems_1[, c("station", "flow2", "occupancy2")]
pems_2 = pems_2[, c("station", "flow2", "occupancy2")]
```
This would appear to just make a gratuitous copy.
But I just checked, it doesn't actually copy anything, so it's effectively a non-op.
Thus we do not gain any efficiency by removing the line.
Removing the line would decrease readability, and require more special logic, so this seems like a worse option.

------------------------------------------------------------

Next line:

```{r}
pems2 = split(pems, pems$station)
```

Above I wrote that the vectorized expansions keep track of which variables are chunked.
This doesn't actually handle the splitting.
We could augment it by keeping track of which variables are chunked and whether or not they are chunked with respect to a variable.

Alternatively, we could leave the `split` in there and generate this code:

```{r}
pems2_1 = split(pems_1, pems_1$station)
pems2_2 = split(pems_2, pems_2$station)

results_1 = lapply(pems2_1, npbin)
results_2 = lapply(pems2_2, npbin)

results = c(results_1, results_2)
```

This approach seems to leave the code in a more complicated state than is necessary, but it has a number of benefits.
It would handle a more general case when the only thing we know about the data is that all the elements for each group will appear in only one chunk, and one chunk may contain multiple groups.
The generated code preserves the semantics, which will again help with understanding and debugging.
It allows us to treat the following line `results = lapply(pems2, npbin)` as just a normal vectorized function; that is, we don't need to know anything special about the grouping structure.

What logic will allow us to do this?
This is the same as treating `split` as a vectorized function.
We know `pems` is chunked on the column `station`.
When we see `split(pems, pems$station)`, we can treat `split` as being vectorized.
That is essentially it.



------------------------------------------------------------

Final (difficult) line:

```{r}
results = lapply(pems2, npbin)
```

We cannot handle this `lapply` as we do other vectorized function calls, because the `lapply` is over the split elements.
This is a special case that we will have to handle.
Going into this function the code expander can know that `pems2` is split by a grouping variable.


## Two ways to implement vectorized statement expansion

I have two options in mind, and I'm not sure which one is better.
One way is to create temporary variables, and the other way is to traverse the task graph.

The core logic of searching for vectorized calls that can be parallel will be the same for both.
Being chunked or not becomes a property of an R object, a resource.

Choosing one over the other amounts to analyzing and transforming the code, or the task graph.
I think it's better to stick closer to the code, because then it doesn't require that a user to really understand the task graph.
If the graph inference is robust we can always get the graph from the code whenever we like.


#### Option 1 - creation of temporary variables

The first way is to preprocess the code to take out the nested subexpressions, and insert them as temporary variables.
For example, for large chunked objects `x` and `y`:
```{r}
# Original
z = 10*x + y

# Step 1 - Create temporary variables
tmp = 10*x
z = tmp + y

# Step 2 - Expand vectorized `*` and `+`
tmp1 = 10*x1
tmp2 = 10*x2
z1 = tmp1 + y1
z2 = tmp2 + y2
```

Expanding vectorized statements in this literal sense for `k` chunks of data ties us tightly to having only `k` parallel workers.
For data that can be split arbitrarily it may be better to mark the statements after Step 1 as those which are vectorized, and save the actual expansion for later, or possibly never even expand.

Pros:

- Works better with everything I already have.
- Allows us to use relatively simple logic for expanding vectorized function calls.
- Simplifies the task graph conceptually, because nodes have a one to one correspondence with top level statements in the script after this transformation.
- Creating temporary variables is necessary to generate code that uses parallelism in subexpressions.
    An example is sending one intermediate result from one worker to two other workers.
    If we'll have to do something very much like this transformation anyways, then we may as well derive as much benefit from it as we can.

Cons:

- We'll need to insert code to remove the temporary variables.
    This isn't too much of an issue, becaue we were going to do this anyways.


#### Option 2 - traversing task graph

The second way to expand vectorized statements is to work our way through the task graph, where nested subexpressions are tasks.

How would we actually implement this?
The task graph must actually contain the nested subexpressions.
The current version of the task graph does not contain nested subexpressions, so I used recursion into the subexpressions.
This was clumsy at best.

The difficult thing is when we actually go to expand the code, we have to keep in mind our position in the graph, where in the graph to insert the nodes, and which edges in the graph to update based on these changes.
I've written more about all this in `clarkfitzthesis/tex/expand_vectorized.tex`.

Thus we need to keep the overall structure of the task graph in mind, and this makes things difficult.
With the other approach we can simply insert the collects directly in front of the statement we are currently looking at, and then infer the graph again later after we generate the code.

Pros:

- Better suited to a series of task graph transformations.

Cons:

- Complicated, difficult to implement.


## Identifying semantically meaningful objects

I've settled on rewriting the code.
Now I need to detect these two patterns in a more robust way:

```{r}
tmp1 = c("station", "flow2", "occupancy2")
pems = pems[, tmp1]

tmp2 = pems[, "station"]
s = split(pems, tmp2)
```

A more robust way to detect the pattern should assign semantic meaning to each object.
We can infer the semantics much in the same way as we evaluate code.
If it's going to be extensible then it should allow the user to add more rules, and apply these rules.

In the examples above, the analysis begins knowing that `pems` is a large, chunked data frame, because the users provided this information.
Starting with the first line, it recognizes the pattern of `c("station", "flow2", "occupancy2")` as a call to `c` with only literal arguments.
To infer which columns are used we need to know the actual value of this object.
The code analyzer could infer the value, or it could just evaluate it.
It's generally safe to evaluate a call to `c` with only literal arguments.
Specifying when evaluation is safe is simpler than specifying the semantics of every single function that we might evaluate.
In the inference approach we would be specifying the semantics, i.e. rules to infer the result every possible combination of literal arguments, for example `c("a", 1)`.
This is essentially just (re) implementing a simple evaluator.

Indeed, the most straightforward and complete way to understand an object is to evaluate the code.
This makes me think that an analysis based on partial evaluation has some merit.

The analysis now knows the value of `tmp1`, and can proceed to the next call, `pems = pems[, tmp1]`.
This is a column selection of the `pems` data object, for known values of the columns.
We cannot evaluate this call directly, because `pems` is huge.
All we do is update the columns used.
It reassigns `pems`, which becomes a new chunked data object with the same name as the old one.

The next line is `tmp2 = pems[, "station"]`.
This again takes a subset of the pems columns.
Since the chunks are by rows, `tmp2` will also be a large chunked object with the same chunking scheme as `pems`.

The last line is `s = split(pems, tmp2)`.
The analysis knows that `pems` and `tmp2` are large chunked objects with the same chunking scheme.
The data description told the analysis that the chunks of data are already separated by the `station` column of `pems`.
The argument for the splitting factor is `tmp2`.
The analysis needs to know that `station` is one of the columns in `tmp2`.
Thus it needs to know semantically what `tmp2` actually contains.

Side note:
We don't have to distinguish between single column splits and multiple column splits, because `split` in R allows a list of factors.

How will the analysis propagate the semantics of which columns a chunked object contains?
The chunk expansion already propagates the names of the variables that have the same chunking scheme.
The code analysis should be able to attach any other information it likes on top of this.
The current implementation uses a named list where the element name is the variable name and the value is the names of all the expanded variables.
We could make this more general and extensible by making the values be lists that contain the names of the columns.
Then we can add `columns` as a field.

But if we're going to all this trouble then we may as well do the whole 'limited evaluation' approach at this time as well.


## Limited Evaluation

Go through the code and expand the objects that can be expanded.
What exactly happens?
For every expression the code analyzer starts out with state, a set of variable names that are known.
The values associated with these variable names can be chunked data objects, simple values (such as `c("a", "b")`), or other things that we don't know about.
To work for the PEMS use case the code analyzer should look at the expression and determine which columns of the original large data set it uses.

Suppose the code analyzer has the following symbols defined. `x` is a large chunked data object, and `ab = c("a", "b")` is a known simple value.
Then the line
```{r}
y = x[, ab]
```
will create a new chunked object `y` which uses columns `a` and `b` from the large chunked object `x`.


Inference could happen at this pass also- we can collect the set of all columns that are used.
Will this lead to a coherent model?
I'm not sure.

Could I plug into `CodeDepends` for any of this?
Possibly.
I need something like the function handlers to keep track of what is used.

------------------------------------------------------------

A current problem with the implementation is that I'm representing the data description in several forms.
I care about which columns the data contain at each step in the code, and whether the data is split based on one of these columns.
Sometimes it's a slot in a class, sometimes it's in a list, and now sometimes it's tacked on as an attribute.
I need to consolidate these into one representation, so I can use the model of limited evaluation.
We may as well stick with the S4 class representation, as most of the rest of the package uses S4.

In the limited evaluation model we analyze one expression at a time, given variables that we know things about.
The variables can be chunked data objects, known simple values, or they can be things we know nothing about.
We can use the same `expandData` generic, just add a signature for a `call` and `list` argument.
The `call` is simply one statement, and the `list` is a list of current variables that we know about.

I'm discovering that I need to dispatch on classes for the code.


## Scratch

Injecting the data loading code could definitely benefit from method dispatch.
But isn't it the same as expanding data?
I would like to dispatch on the characteristics of the platform.
This suggests that I have classes for all the different platforms I want to use.
This will also be useful later for generating code.


I wonder if we could get the S4 to pass a default argument without dispatching on it.
It seems like I tried this before.


