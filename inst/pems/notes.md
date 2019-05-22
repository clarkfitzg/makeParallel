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

## Data Description 2


```{r}
pems_ds = dataFiles(dir = "stationID", format = "text", class = "data.frame", splitColumn = "station",
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
