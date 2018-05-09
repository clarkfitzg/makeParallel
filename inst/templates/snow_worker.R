if(ID != {{{processor}}})
    stop(sprintf("Worker is attempting to execute wrong code.
This code is for {{{processor}}}, but manager assigned ID %s", ID))

{{{code_body}}}
