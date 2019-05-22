
Mon May 20 09:54:07 PDT 2019

Goal: get the PEMS example fully working.
This means to the point where I can just call `makeParallel("pems.R", data = dd, workers = 10L)`, where `dd` is a data description written by the user.

All of the semantics of the program should be contained within `pems.R`.
One exception is the data reading code, since we'll generate that.

First priorities:

- implement data description.
    This should include the values of the column to GROUP BY, along with counts.
- get the version working that handles data that's already split in the files.
- detect GROUP BY pattern in source code (code analysis).
    This is really just looking for a `by`, or a `split`.
- X determine which columns in a data frame are used (code analysis).

Second priorities:

- recursively detect function calls that are used, so we can ship all the necessary functions to the workers (code analysis)
- implement re-grouping operation, aka shuffle.


------------------------------------------------------------

TODO list:

- handle library calls
- Move some simple cases from tests to the function examples

Can defer:

- See about using CodeDepends::getTaskGraph
- Revisit Apache hive code generation function
- Global option for overwriting files

Done:

- Make sure documentation can be accessed
- Properly cite references
- Drop all the functions and objects that I don't use
- All items in code marked `TODO:*`
- Don't open up sockets for tests on CRAN machines
- Only write to tmp directories
- Make sure object naming convention and argument names are consistent for
  all exported objects.
- Pass R CMD check
- igraph conversion example
- Add error classes to messages
- Unit tests passing
- Run tests on generated code
- Switch to S4
- Read templates when necessary
- Return expression objects rather than text



- What's the best way to keep the arguments to schedule() consistent? I could
  put them in the generic, but it's not clear that I want to dispatch on
  them. Right now they're in scheduleTaskList.

Duncan's answer: Put the arguments in the generic if and only if every
method should use and respect this same set of arguments.


Fri Jun  8 12:00:36 PDT 2018

Talking with Duncan has gotten me to think more deeply about what kind of
object oriented system I want to use. S3 is simpler while S4 is more
complex. But I don't understand either of them, because this passing
default arguments has got me confused. Do any R S3 methods use default
arguments?

Conceptually there are 3 important objects: TaskGraph, Schedule,
GeneratedCode

I would like to have these features right now:

- methods to create a TaskGraph from different inputs
- plot methods for TaskGraph
- Allow user to define their own code_generator function to dispatch on
  Schedule and return object of GeneratedCode
- The flexibility to add arbitrary elements to classes

In the future I might like to have these features:

- summary, print, and more plot methods
- ways to describe data and systems so that these feed into the scheduling
- object validation for Schedule objects, because one can
create schedules that aren't valid (which implies problems with the
schedule generator)


# TODO


Less urgent:

- Conversion to igraph objects
- preprocessing step
- Alternative scheduling algorithm and code generator based on fork / join.
- Measure CPU utilization during timings to see what's parallel / threaded.


## Done

- Show a realistic script as an example that actually benefits from task parallelism.
- Vignettes.
- Robust test for expression equality
- Write the `data_parallel()` function, including modification of for loops
  into parallel code.
- Handle assignment inside of a for loop of the form `x[[i]] = ...`
