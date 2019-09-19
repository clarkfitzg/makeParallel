Thu Sep 19 12:39:14 PDT 2019

Sysadmin (Nehad) checked the logs for me, we can see where the OOM killer killed one of the processes when it used ~31 GB of memory.
10 of these ran at the same time, so cumulatively that's well beyond the available memory.

```
-----
(poisson)-nehad# grep 80776 /var/log/messages
Sep 18 17:41:04 poisson kernel: [80776]  5003 80776  4172201  4094530    8103        0             0 R
Sep 18 17:42:50 poisson kernel: [80776]  5003 80776  4930571  4852934    9588        0             0 R
Sep 18 17:43:43 poisson kernel: [80776]  5003 80776  6067164  5989532   11807        0             0 R
Sep 18 17:45:51 poisson kernel: [80776]  5003 80776  7838782  7761075   15270        0             0 R
Sep 18 17:45:51 poisson kernel: Out of memory: Kill process 80776 (R) score 98 or sacrifice child
Sep 18 17:45:51 poisson kernel: Killed process 80776 (R) total-vm:31355128kB, anon-rss:31043484kB, file-rss:816kB, shmem-rss:0kB
(poisson)-nehad#
```

output of `sar` shows peaks when I ran the jobs, no news there.

```
-----
05:00:01 PM kbmemfree kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty
05:10:01 PM  31472168 232389208     88.07     22184   2374684 289188260     91.47 221313540   7523208       128
05:20:02 PM 200918108  62943268     23.85     24908   2428652 119960352     37.94  52169564   7525276       192
05:30:01 PM 200817524  63043852     23.89     30304   2440164 120134452     38.00  52275040   7537048       260
05:40:01 PM  20265864 243595512     92.32     32976  10138524 292578888     92.54 224802008  15233900       208
05:50:01 PM 199755708  64105668     24.30      3660   3001872 120663040     38.17  52606052   8232316        68
06:00:01 PM 200031020  63830356     24.19     14088   3024628 120317968     38.06  52346576   8257040        80
06:10:01 PM 199558260  64303116     24.37     19708   3084980 120618536     38.15  52764052   8317812       128
06:20:01 PM 200100004  63761372     24.16     21720   3085984 120067260     37.98  52218672   8318720       244
-----
```


------------------------------------------------------------

With 10 workers in parallel on the same 50 files this runs in 5 minutes, about 3 times faster.
My parallel `split` implementation is disk based, so it takes 2.5 minutes.

```
This code was generated from R by makeParallel version 0.2.0 at 2019-09-19 08:51:52
starting
read in files and rbind: Time difference of 0.05943608 secs
split: Time difference of 2.34454 mins
actual computations: Time difference of 12.20462 secs
save output: Time difference of 0.7329969 secs
   user  system elapsed
  1.155   0.147 317.789
```

I watched `top` as it runs- CPU stays close to 100%, which means that it's CPU bound, not IO bound from when it writes the intermediate computations.


Thu Sep 19 08:41:30 PDT 2019

The serial version on 50 files runs in 16 minutes.

```
> system.time(source("~/dev/makeParallel/inst/pems/pems_with_data_load.R"))
starting
read in files: Time difference of 11.9573 mins
rbind: Time difference of 1.029486 mins
split: Time difference of 1.87391 mins
actual computations: Time difference of 51.65321 secs
save output: Time difference of 0.541415 secs
   user  system elapsed
880.788  63.031 943.844
```


Thu Sep 19 08:25:19 PDT 2019

I'm trying to verify how these are killed.
When I `kill -9` an interactive R terminal by process ID I see:

```
> Killed
clarkf@c0-14 ~/data/scratch
```

Start a cluster:

```
library(parallel)
cls = parallel::makeCluster(2, outfile = "workers.log")
clusterEvalQ(cls, Sys.getpid())
```

Now I send the same `kill -9` to one worker.
Nothing shows up in the log file after this.
This may be because of the `--slave` flags to `Rscript` that are passed to the workers that prevent output.
I could fool around with this, but it isn't a priority.
I know the processes are getting killed, because they stop existing.





Wed Sep 18 20:31:22 PDT 2019

And it's dead, in the same way as on Poisson, apparently.
Processes just falling over.

```
  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ CO
19454 clarkf    20   0 58.567g 0.037t   3252 D   2.0 14.9  26:58.01 R
19552 clarkf    20   0 51.579g 0.032t   4032 D   1.3 12.8  27:12.89 R
19670 clarkf    20   0 56.333g 0.039t   4036 D   1.3 15.9  27:55.63 R
19789 clarkf    20   0 57.808g 0.038t   4112 D   1.3 15.6  26:46.38 R
19848 clarkf    20   0 55.896g 0.039t   4120 D   1.3 15.7  27:21.35 R
21824 clarkf    20   0   40780   4072   3136 R   1.0  0.0   0:00.22 to
19503 clarkf    20   0 53.353g 0.036t   3388 D   0.3 14.7  27:36.23 R
18096 clarkf    20   0   20732    204    192 S   0.0  0.0   0:00.04 ba
19119 clarkf    20   0 1343524   6896    572 S   0.0  0.0   0:04.65 R
19907 clarkf    20   0 41.107g 0.023t      4 S   0.0  9.4  23:09.60 R
```


Wed Sep 18 19:18:05 PDT 2019

Just checked top again on the cluster node where I'm running.
Now they've maxed out memory, as I expected.
We'll see if it fails, or just swaps forever.
At least this is different from Poisson.

```
  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COM
19848 clarkf    20   0 29.021g 0.026t    736 D  29.3 10.7  14:13.27 R
19454 clarkf    20   0 26.578g 0.024t   3452 R  26.1  9.8  13:51.67 R
19670 clarkf    20   0 25.917g 0.024t    552 D  26.1  9.7  13:58.68 R
19503 clarkf    20   0 30.136g 0.026t    720 D  10.1 10.7  14:01.14 R
19405 clarkf    20   0 26.955g 0.023t   1292 D   8.5  9.5  13:49.75 R
19789 clarkf    20   0 25.863g 0.024t   1616 D   5.2  9.6  13:56.69 R
19730 clarkf    20   0 26.564g 0.024t    968 D   2.6  9.7  14:04.04 R
19552 clarkf    20   0 27.055g 0.023t    468 D   2.0  9.5  14:08.57 R
19607 clarkf    20   0 27.763g 0.025t   3232 D   1.0 10.1  13:55.95 R
20493 clarkf    20   0   40856   3980   2992 R   1.0  0.0   0:00.09 top
19907 clarkf    20   0 28.312g 0.025t    424 D   0.7 10.0  13:53.68 R
```


Wed Sep 18 19:01:43 PDT 2019

I put the data on the cluster and am trying to run it with 10 processes on 1 node.
I foresee a couple issues:

- Each node only has 64 GB memory, which is way too small.
  This will probably exceed memory and swap, and the program will fail.
- My shuffle implementation should use the local disk, rather than going to and from NFS.
  This may or may not be a big deal.

Watching `top` on that node I see the workers happily running away.
Nothing else is happening on that node, which is good.


Wed Sep 18 17:47:19 PDT 2019

Now The processes have been terminated, and I don't know why.

```
   PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
 80880 clarkf    39  19   27.6g  27.3g   1072 R 100.0 10.8  14:14.79 R
 80815 clarkf    39  19   27.8g  27.5g   1472 R 100.0 10.9  14:16.15 R
 80828 clarkf    39  19   27.0g  26.7g   1472 R 100.0 10.6  14:18.43 R
 80854 clarkf    39  19   29.9g  29.6g   1468 R 100.0 11.8  14:15.98 R
 80867 clarkf    39  19   30.3g  30.0g   1468 R 100.0 11.9  14:18.19 R
 80893 clarkf    39  19   28.6g  28.3g   1472 R  99.3 11.3  14:16.56 R
```

When I run `stopCluster` nothing happens, I have to go in and kill them by hand.


Wed Sep 18 17:37:47 PDT 2019

Trying it again with 10 workers instead of 20.
I see them all here working as they should.
They have all been alive for 4 minutes and 20 seconds, good they started at the same time.

```
 80776 clarkf    39  19   10.1g   9.8g   7876 R 100.0  3.9   4:20.18 R
 80854 clarkf    39  19 9189092   8.5g   7876 R 100.0  3.4   4:20.31 R
 80893 clarkf    39  19 8807588   8.1g   7876 R 100.0  3.2   4:20.31 R
 80802 clarkf    39  19   10.0g   9.7g   7876 R 100.0  3.8   4:20.32 R
 80815 clarkf    39  19 9061364   8.4g   7876 R 100.0  3.3   4:19.33 R
 80828 clarkf    39  19   10.5g  10.2g   7876 R 100.0  4.0   4:20.42 R
 80841 clarkf    39  19   10.1g   9.8g   7876 R 100.0  3.9   4:20.30 R
 80867 clarkf    39  19 9989.7m   9.5g   7876 R 100.0  3.8   4:20.37 R
 80789 clarkf    39  19 9801776   9.1g   7876 R  99.7  3.6   4:20.25 R
 80880 clarkf    39  19 9924576   9.2g   7876 R  99.0  3.6   4:20.27 R
```

-------
Earlier:

Debugging this now. I expected to see more of my processes running:

Here is the output of top for my user:

```
 75951 clarkf    39  19   16.9g  16.6g   1372 R 100.0  6.6   5:23.05 R
 76020 clarkf    39  19   20.0g  19.7g    880 R 100.0  7.8   5:23.50 R
 76052 clarkf    39  19   20.7g  20.4g    320 R 100.0  8.1   5:24.22 R
 76134 clarkf    39  19   20.4g  20.1g    320 R 100.0  8.0   5:23.43 R
 76241 clarkf    39  19   21.1g  20.8g   1360 R 100.0  8.3   5:24.27 R
 76277 clarkf    39  19   17.7g  17.4g    880 R 100.0  6.9   5:23.31 R
 76303 clarkf    39  19   20.1g  19.8g    880 R 100.0  7.9   5:22.97 R
 76098 clarkf    39  19   20.8g  20.5g    320 R 100.0  8.2   5:23.83 R
 76186 clarkf    39  19   17.3g  17.0g   1376 R  99.7  6.8   5:23.68 R
```

It uses a bunch of memory, as I expected.
Then it dies.
Is it getting killed?
Another user has come on and is using lots of CPU, a professor with more privileges.

Looks like zombies may well be the issue:
```
 75951 clarkf    39  19   50.1g  49.9g    836 S   0.0 19.8  10:24.39 R
 76098 clarkf    39  19   56.5g  56.2g    872 S   0.0 22.3   9:42.25 R
 76134 clarkf    39  19   55.6g  55.3g    840 S   0.0 22.0  10:19.09 R
```

OK, killed them, they are gone.
But they are only 10 minutes old... which means they are left over from the most recent command.
Why are their ages so different? By 40 seconds, close to a minute.
They should have been created within seconds of each other.


Wed Sep 18 11:18:56 PDT 2019

Ran a test version on 10 of the 300 files with 5 workers.
Takes 143 seconds.
So with 20 workers to do all the data it should take around:

143 * (300/10) * (5/20) *(1/60) = 18 minutes.

Hmmm, we shall see.


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

I'm discovering that I need to dispatch on classes for the code, and thus I need something like the classes in rstatic.

------------------------------------------------------------

How do we propagate the literal values through?
Right now I'm having trouble because the known literal values are in a list mixed with the ChunkedData objects.

------------------------------------------------------------

What's fouling me up?
I'm trying to be too clever forcing everything to dispatch on this `expandData` method and using `callGeneric`.


## Implementation

How does all the expansion based on the data work?

#### Objects 

- TableChunkData: Contain all the information about the data chunks, in particular:
      - variable name from the original code
      - expanded variable names, that is, the names of every chunk after name mangling
      - the names of the columns that this table contains
      - whether the object has already been collected
- globals: named list representing the objects in the global environment that we care about during partial evaluation, which is a subset of all globals the script defines.
      Values have class either `TableChunkData` or `KnownStatement`.


#### Algorithm

The expansion algorithm can be thought of as partial evaluation.
It works one statement at a time, ignoring control flow and conditional statements for the moment.
This first implementation handles each statement in one of three possible ways:

1. If a statement is a call to a vectorized function, say `y = 2 * x`, and any of the vectorized arguments are chunked data objects, then the algorithm infers a new chunked data object from this statement, supplementing it with information from the globals.
      It inserts this object into the globals.
2. If a statement is a simple literal call, say `ab = c("alpha", "bravo")`, then the algorithm evaluates it, and inserts the resulting object into the globals.
3. Otherwise, the statement is unknown.
      The algorithm collects any expanded variables that appear in the statement, and marks them in the globals as collected.
      It's natural to do both of these tasks in the same step.

In every case the algorithm may potentially update the globals.
The new code gets appended to the existing code.


## Order

To infer which columns are used we need to walk over the whole code, and look at every subset `[` operation on the chunked data objects.
This is the same time that we'll need to partially evaluate things.
For example, in the code below we need to know the value of `cols` before we can infer which columns `pems` will use.
```{r}
cols = c("a", "b")
pems[, cols]
```
Only once we know all the columns that are used can we go back and generate the correct calls to read in the data.

Currently I'm generating the calls in the same pass as when I partially evaluate it.
This approach cannot work for generating the intial data loading call, because we don't yet know which columns will be loaded.

However, we can prepend the data loading code later after we've generated all the rest of the code and we know which columns are used.


## Status

Duncan commented that it looks like this approach does two things at once- inferring which columns are used, and which columns split the data at the same time that it expands the code.
This isn't ideal- the inference about the code should be separate from the modification.
Furthermore, we need a more general mechanism for specifying the semantics of the functions, something like the CodeDepends function handlers that can potentially do something different for every function.
As it stands now I've hardcoded in the logic for `[` and `split`.

I think the problem is that I leapt too quickly into the implementation without precisely thinking through what needed to happen.
That is, I was thinking about the minimum required to get the PEMS example running, but not how it can generalize.
As the major flaws manifested themselves I kept reworking it to be more general.
Now this implementation has gotten away from me a little bit, and I realize that it's unlikely to be ideal.
This seems like a good time to go back and ask what features I really need an implementation to provide.

The other thing I was doing with the code expansion was making something that would work with the existing scheduler and code generator.
That's a reasonable enough thing to do.


## Scratch

Injecting the data loading code could definitely benefit from method dispatch.
But isn't it the same as expanding data?
I would like to dispatch on the characteristics of the platform.
This suggests that I have classes for all the different platforms I want to use.
This will also be useful later for generating code.


I wonder if we could get the S4 to pass a default argument without dispatching on it.
It seems like I tried this before, and I think it's possible.


Data splitting- suppose we have a vectorized computation with `w` workers, and `w + 1` evenly sized groups.
Then we would want to split one group among all the workers to balance the loads, or one worker will have to do 2 units of work, while all the others do 1.

#### Describe Data

This is straightforward and the inital version pretty much works.
The data description provides information to generate the code to load it in.
I used it in `transform_code.R`.

Duncan would rather infer this data description given the code, but we can always come back and do that later.
I would prefer not to do this, because data that is actually challenging to handle, i.e. files that won't fit in memory, require specialized code to load it in.
I feel that this specialized code will be difficult to handle generally.
For example, we don't want to try to analyze a bash command called from R such as `pipe("unzip -p datafiles/* | cut ...)`, but we would be happy to generate code like this.


