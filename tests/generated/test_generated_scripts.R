#!/usr/bin/env Rscript

# This scripts tests generated code. It requires certain ports to be open,
# writes local files, and sometimes uses 3 worker processes, so it can't
# run on CRAN.
#
# Each script should write results to a file following the current naming
# convention. For example, script1.R writes output to script1.R.log.


library(makeParallel)


expect_generated = function(script, scheduler = scheduleTaskList, plot = FALSE, ...)
{
    cat(sprintf("Testing %s\n", script))

    # Check that the output of the file is the same for the serial script
    # and the generated script.

    outfile = paste0(basename(script), ".log")
    serfile = paste0("expected_", outfile)
    p = makeParallel(script, scheduler = scheduler, overWrite = TRUE, ...)

    if(plot){
        pdf(paste0(script, ".pdf"))
        plot(schedule(p))
        dev.off()
    }

    # Serial
    source(script, local = new.env())
    file.rename(outfile, serfile)
    expected = readLines(serfile)

    # Parallel
    # Generated scripts have a cluster `cls`. It needs to be cleaned up if
    # something fails midway through.
    #on.exit(try(parallel::stopCluster(cls), silent = TRUE))

    code = writeCode(p, file = FALSE)
    eval(code)
    actual = readLines(outfile)
    
    stopifnot(identical(actual, expected))

    cat(sprintf("Pass %s\n\n", script))
}

# A test of the test :)
e = tryCatch(expect_generated("fail.R"), error = identity)


# Special cases:
############################################################

expect_generated("script3.R", maxWorker = 3)


# Run all with the defaults:
############################################################

scripts = Sys.glob("script*.R")
lapply(scripts, expect_generated)
