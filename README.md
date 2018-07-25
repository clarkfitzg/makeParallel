# makeParallel

Transform Serial R Code into Parallel R Code

Writing parallel R code can be difficult, particularly for code that is
not "embarrassingly parallel". This experimental package automates the
transformation of serial R code into more efficient parallel versions. It
identifies task parallelism by statically analyzing entire scripts to
detect dependencies between statements. It implements an extensible system
for scheduling and generating new code. It includes a reference
implementation of the 'List Scheduling' approach to the general task
scheduling problem of scheduling statements on multiple processors.

Quickstart:
[vignettes/quickstart.Rmd](https://github.com/clarkfitzg/makeParallel/blob/master/vignettes/quickstart.Rmd).

Concepts:
[vignettes/concepts.Rmd](https://github.com/clarkfitzg/makeParallel/blob/master/vignettes/concepts.Rmd).

<!--
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/makeParallel)](https://cran.r-project.org/package=makeParallel)
-->

[![Build
Status](https://travis-ci.org/clarkfitzg/makeParallel.svg?branch=master)](https://travis-ci.org/clarkfitzg/makeParallel)
