processor = {{{processor}}}

# SNOW manager sets the ID
if(processor != ID)
    stop("Worker is attempting to execute wrong code.")

{{{code_body}}}

message(sprintf("Worker %d finished.", ID))
