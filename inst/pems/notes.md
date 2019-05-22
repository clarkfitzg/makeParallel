Goal: get the PEMS example fully working.
This means to the point where I can just call `makeParallel("pems.R", data = dd, workers = 10L)`, where `dd` is a data description written by the user.

All of the semantics of the program should be contained within `pems.R`.
One exception is the data reading code, since we'll generate that.

First priorities:

- get the version working that handles data that's already split in the files.
- detect GROUP BY pattern in source code (code analysis).
    This is really just looking for a `by`, or a `split`, particularly for the case when the data starts out split by that same variable.
- X determine which columns in a data frame are used (code analysis).
- X implement data description.
    This should include the values of the column to GROUP BY, along with counts.

Second priorities:

- recursively detect function calls that are used, so we can ship all the necessary functions to the workers (code analysis)
- implement re-grouping operation, aka shuffle.


------------------------------------------------------------

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

