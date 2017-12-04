# RHive

Run R code in Hive

Extending and generalizing the ideas from [this blog
post](http://clarkfitzg.github.io/2017/10/31/3-billion-rows-with-R/)

## Prior Work

The 

## Example

```{R}

library(RHive)

testfunc = function(x)
{
    data.frame(station = 1L, n_total = 2L, slope = 3.14)
}

write_udaf_scripts(f = testfunc
    , cluster_by = "station"
    , input_table = "pems"
    , input_cols = c("station", "flow2", "occ2")
    , input_classes = c("integer", "integer", "numeric", "character")
    , output_table = "fundamental_diagram"
    , output_cols = c("station", "n_total", "slope")
    , output_classes = c("integer", "integer", "numeric")
    , overwrite_script = TRUE
    , overwrite_table = TRUE
    , try = TRUE
)

```


Some ideas talking with the code review group:

```
input_table 
data
data_in
SELECT_FROM
select_from

sql_in = sql_builder(SELECT = c("col_a", "col_b")...)
```
