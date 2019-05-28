Goal: get the PEMS example fully working.
This means to the point where I can just call `makeParallel("pems.R", data = dd, workers = 10L)`, where `dd` is a data description written by the user.

All of the semantics of the program should be contained within `pems.R`.
One exception is the data reading code, since we'll generate that.

The first priority is to get the version working that handles data that's already split in the files.

- handle `split(data, data$column)` as a special case when `data` is a chunked object that is split by column.
- Transform the code 
```{r}
# Before:
pems = pems[, c("station", "flow2", "occupancy2")]

# After
tmp1 = c("station", "flow2", "occupancy2")
pems = pems[, tmp1]
```
This will make the call to `[` simple.
_Ah, but what's this going to break with how I did the column use inference?_
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

_Did I write all this somewhere else also? It seems familiar_

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







## Scratch

Injecting the data loading code could definitely benefit from method dispatch.
But isn't it the same as expanding data?
I would like to dispatch on the characteristics of the platform.
This suggests that I have classes for all the different platforms I want to use.
This will also be useful later for generating code.


I wonder if we could get the S4 to pass a default argument without dispatching on it.
It seems like I tried this before.


