# makeParallel

Transform Serial R Code into Parallel R Code

[![Build
Status](https://travis-ci.org/clarkfitzg/makeParallel.svg?branch=master)](https://travis-ci.org/clarkfitzg/makeParallel)

Writing parallel R code can be difficult, particularly for code that is
not "embarrassingly parallel". This experimental package automates the
transformation of serial R code into more efficient parallel versions. It
identifies task parallelism by statically analyzing entire scripts to
detect dependencies between statements. It implements an extensible system
for scheduling and generating new code. It includes a reference
implementation of the 'List Scheduling' approach to the general task
scheduling problem of scheduling statements on multiple processors
discussed in Sinnen (2007) <ISBN:0471735760>.

Quickstart:
[vignettes/quickstart.Rmd](https://github.com/clarkfitzg/makeParallel/blob/master/vignettes/quickstart.Rmd).

Concepts:
[vignettes/concepts.Rmd](https://github.com/clarkfitzg/makeParallel/blob/master/vignettes/concepts.Rmd).
