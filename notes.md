## Notes

Working notes as I enhance the package.


Wed Apr  3 10:20:45 PDT 2019


I think it's more clear conceptually for the `data` to be an argument to the scheduler.
The scheduler is the component that makes decisions about when and where to use the data.
It could be useful in the code analysis step when we try to follow the large data objects through the program.
But the scheduler can always do this kind of analysis that follows an object through the script, because it has the dependency graph and the code.
