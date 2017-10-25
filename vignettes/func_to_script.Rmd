Wed Oct 25 08:11:10 PDT 2017

Thinking about Scott's water simulation use case now. Essentially we have
some `lapply()` call that should be converted into code that runs on an HPC
environment, ie. a SLURM cluster.

What does R's `batchtools` package already provide? Reading through their
vignette it appears to be more designed for the interactive use case.

There's also the `rslurm` package. It would be nice if this had some kind
of "local" mode for debugging before submitting the job.
I'm going to try running their hello world.

`rslurm` produces just what I want: it wraps the function up in an
mcmapply, serializes the functions and data into files to be put on the
cluster, generates R scripts to run on the workers, and generates an
`SBATCH` submission script. Then it executes the job, checks the status,
and collects the results in a reasonable way.
What more could I ask for?
