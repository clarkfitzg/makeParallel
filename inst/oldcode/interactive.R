## ------------------------------------------------------------------------

library(autoparallel)

x = list(1:10, rnorm(10), rep(pi, 10))

do = makeParallel(x)
do


## ------------------------------------------------------------------------

lapply(x, head)

do(lapply(x, head))


## ------------------------------------------------------------------------

y <<- 20
z <<- 30
do(y + z, verbose = TRUE)


## ------------------------------------------------------------------------

# An analysis function
myfun <<- function(x) x[1:2]

do(lapply(x, myfun))

# Oops I actually need the first 4
myfun <<- function(x) x[1:4]

# Now we see the new results of myfun
do(lapply(x, myfun))


## ---- eval = FALSE-------------------------------------------------------
#  
#  # Any large R object
#  big = 1:1e8
#  
#  object.size(big)
#  
#  # BAD IDEA: this sends `big` over every time
#  do(sum(big + x[[1]][1]))
#  

## ------------------------------------------------------------------------

print.function(do)


## ------------------------------------------------------------------------

do(lapply(x, head), simplify = FALSE)


## ------------------------------------------------------------------------

stop_cluster(do)


## ---- echo = FALSE-------------------------------------------------------

# Used on my local machine only
datadir = "~/data/vets/appeals_sample"


## ----download, eval = FALSE----------------------------------------------
#  
#  datadir = "vets_appeals"
#  dir.create(datadir)
#  
#  fnames = paste0("1719", 100:266, ".txt")
#  urls = paste0("https://www.va.gov/vetapp17/files3/", fnames)
#  
#  Map(download.file, urls, fnames)
#  

## ------------------------------------------------------------------------

filenames = list.files(datadir, full.names = TRUE)
length(filenames)

do = makeParallel(filenames)


## ------------------------------------------------------------------------

do({
    appeals <- lapply(filenames, readLines)
    appeals <- sapply(appeals, paste, collapse = "\n")
    appeals <- enc2utf8(appeals)
    NULL
})


## ------------------------------------------------------------------------

"appeals" %in% ls()


## ------------------------------------------------------------------------

ten <<- 10
do(ten + 1, verbose = TRUE)


## ------------------------------------------------------------------------

do(length(appeals))
do(class(appeals))


## ------------------------------------------------------------------------

# Check how many we're about to bring back
do(sum(grepl("REMAND", appeals)))

# Bring them back from the workers
remand <- do(appeals[grepl("REMAND", appeals)])

length(remand)


## ------------------------------------------------------------------------

stop_cluster(do)


