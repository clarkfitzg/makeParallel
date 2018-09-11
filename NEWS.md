# News

## 0.2

- Enhancement: Sort `DependGraph` by node priority before scheduling with `scheduleTaskList`.
- New feature: Plot method for `DependGraph`
- Enhancement: Prevent sending the same data to the same worker multiple times in `scheduleTaskList` function.
- Enhancement: Redesigned `DependGraph@graph` for extensibility.
  Columns are `from`, `to`, `type`, and `value`, where `value` is a list of lists that can contain anything for any row.


## 0.1

31 July 2018

- Initial CRAN submission
