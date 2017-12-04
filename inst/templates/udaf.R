#!/usr/bin/env Rscript

# {{{gen_time}}}
# Automatically generated from R by autoparallel version {{{version}}}

# These values are specific to the analysis
verbose = {{{verbose}}}
rows_per_chunk = {{{rows_per_chunk}}}
cluster_by = {{{cluster_by}}}
sep = {{{sep}}}
input_cols = {{{input_cols}}}
input_classes = {{{input_classes}}}
try = {{{try}}}
f = {{{f}}}


# Other code that the user wanted to include, such as supporting functions
# or variables:
############################################################

{{{include_script}}}

# The remainder of the script is a generic template
############################################################


# Logging to stderr() writes to the Hadoop logs where we can find them.
msg = function(..., log = verbose)
{
    if(log) writeLines(paste(...), stderr())
}


multiple_groups = function(queue, g = cluster_by) length(unique(queue[, g])) > 1


process_group = function(grp, outfile, .try = try)
{
    msg("Processing group", grp[1, cluster_by])

    if(.try) {try({
        # TODO: log these failures
        out = f(grp)
        write.table(out, outfile, col.names = FALSE, row.names = FALSE, sep = sep)
    })} else {
        out = f(grp)
        write.table(out, outfile, col.names = FALSE, row.names = FALSE, sep = sep)
    }
}


msg("BEGIN R SCRIPT")
############################################################

stream_in = file("stdin")
open(stream_in)
stream_out = stdout()

# Initialize the queue
# TODO: parameterize Hive's na.strings
queue = read.table(stream_in, nrows = rows_per_chunk, colClasses = input_classes
    , col.names = input_cols, na.strings = "\\N")

while(TRUE) {
    while(multiple_groups(queue)) {
        # Pop the first group out of the queue
        nextgrp = queue[, cluster_by] == queue[1, cluster_by]
        working = queue[nextgrp, ]
        queue = queue[!nextgrp, ]

        process_group(working, stream_out)
    }

    # Fill up the queue
    nextqueue = read.table(stream_in, nrows = rows_per_chunk
        , colClasses = input_classes, col.names = input_cols, na.strings = "\\N")
    if(nrow(nextqueue) == 0) {
        msg("Last group")
        try(process_group(queue, stream_out))
        break
    }
    queue = rbind(queue, nextqueue)
}

msg("END R SCRIPT")
