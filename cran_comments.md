This is a re-submission for the new package 'makeParallel', now on version
0.1.1. I have incorporated the feedback kindly provided by Swetlana
Herbrandt on July 30th, 2018. See responses inline below.

Thank you,
Clark Fitzgerald

> Thanks,
> 
> makeParallel("script.R")
> 
> cannot run:
> cannot open file 'script.R': No such file or directory
> 
> Please add such a file in your package.

Fixed.

> Please ensure that your functions do not write by default or in your
> examples/vignettes/tests in the user's home filespace. That is not allow by
> CRAN policies. Please only write/save files if the user has specified a
> directory. In your examples/vignettes/tests you can write to tempdir().
> 
> Please fix and resubmit.
> 
> Best,
> Swetlana Herbrandt

I changed the default arguments so that none of the functions write to
files by default. The two offending functions were 'writeCode' and
'makeParallel'. Now the user must explicitly supply the 'file' argument to
write to a file. I verified that all of the examples/vignettes/tests only
write to temporary files or into temporary directories, and then remove
these once they are finished. I clarified this behavior in the
documentation and vignette titled 'quickstart'.


## Test environments
* ubuntu 16.04 local (R 3.4.4)
* ubuntu 14.04 travis-ci (R devel and release)
* win-builder (R devel and release)


## R CMD check results
There were no ERRORs or WARNINGs.

This is the first submission of this package to CRAN, so there is a NOTE.
