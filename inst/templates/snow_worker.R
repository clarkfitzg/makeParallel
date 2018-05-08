# {{{gen_time}}}
# Automatically generated from R by autoparallel version {{{version}}}
# This script contains the code for a single worker.
# It is one component of a larger program.

processor = {{{processor}}}

# SNOW manager sets the ID
if(processor != ID)
    stop("Worker is attempting to execute wrong code.")

{{{code}}}

message(sprintf("Worker %d finished.", ID))
