# Clark: Original file consists of 80K entries to lemmatize. They can all
# happen in parallel.
# The challenge to automatically parallelize this on Windows is to know
# what code must be executed before the main lapply function can run.
#
# Without analyzing the code we could just run all the code before the
# `lapply`. Further this has the structure:
#
# code
# f = function() ... lapply()
# f()
#
# So we would like to: 
#   - create an appropriate cluster
#   - execute the code in the first part on the manager and all the workers
#   - change the lapply to parallel::parLapply
#
# This general strategy won't work with nested `lapply` calls.
# Also don't want to blindly replace every lapply with a parallel version.
# Maybe could have user hints about where to parallelize?


# Clark: this takes about 0.5 seconds. It's 9327 words, which is much
# longer than any letter of recommendation. Do it 80K times and it becomes 11
# hours. But Jared was talking about 100 hours for the whole dataset. What
# am I missing?
#system.time(t1 <- treetag("/home/clark/data/vets/appeals_sample/1719181.txt"))


library(koRpus)
# options(warn = -1)

# Clark: 
fname = "goodnightmoon.csv"
doc = read.csv(fname, header = TRUE, stringsAsFactors = FALSE)


# The only things you need to modify
LemmatizerSourceDir = '/home/clark/dev/tree-tagger'   # Where the lemmatizer source files live


# Clark: CodeDepends doesn't identify any outputs, updates, or side effects
# based on the code below. To do this it needs to recurse inside the body
# of the function. But how far do we proceed examining function bodies?
# Perhaps just into the functions from the package environments.  

# Clark: set.kRp.env manipulates the private environment koRpus:::.koRpus.env
# For a SNOW cluster the only reasonable way to achieve the same result is
# to actually evaluate this code, since we aren't going to try to fool
# around with private variables in a sealed namespace.
#
# CodeDepends doesn't help me to understand what it's doing.
#s = CodeDepends::getInputs(body(set.kRp.env))

#s = CodeDepends::getInputs(quote(
# Set the koRpus environment
set.kRp.env(TT.cmd = "manual",
            lang = 'en',
            preset = 'en',
            treetagger = 'manual',
            format = 'obj',
            TT.tknz = TRUE,
            encoding = 'UTF-8',
            TT.options = list(path = LemmatizerSourceDir,
                              preset = 'en'))
#))

# This function will take in a character vector and output a data frame
lemmatize = function(txt){
  tagged.words = treetag(txt,
                         format = "obj",
                         treetagger ='manual',
                         lang = 'en',
                         TT.options = list(path = paste0(LemmatizerSourceDir),
                                           preset = 'en'))
  results = tagged.words@TT.res
  return(results)
} 

# Clark: The lines between this point and the GSRLem definition are where
# he's developing the function to use.
# They're not necessary, and should be removed in a preprocessing step.

# Run the lemmatizer!
LemmatizedDF = lemmatize(doc[1, "paragraph"])

# Clean Data
LemmatizedDF$lemma = as.character(LemmatizedDF$lemma)

LemmatizedDF[which(LemmatizedDF$lemma == "<unknown>"), "lemma"] = LemmatizedDF[which(LemmatizedDF$lemma == "<unknown>"), "token"]
# Clark: He computes the same condition twice here, when it can't change.
# Unlikely to be a bottleneck in this code, but more generally it could be.
# We could detect and change this to:
#cond = LemmatizedDF$lemma == "<unknown>"
#LemmatizedDF[cond, "lemma"] = LemmatizedDF[cond, "token"]

paste(LemmatizedDF$lemma, collapse = " ")


#### Function ####

GSRLem = function(text.col){
  require(pbapply)
# Clark: Dropping in mclapply here should suffice to parallelize this. But
# original code ran on Windows, so need to do more.
  lemdflist = pblapply(X = text.col, function(x) lemmatize(x))
  rcv = vector()
  for(i in 1:length(lemdflist)){
    activedf = lemdflist[[i]]
    activedf$lemma = as.character(activedf$lemma)
    activedf[which(activedf$lemma == "<unknown>"), "lemma"] = activedf[which(activedf$lemma == "<unknown>"), "token"]
    coltext = paste(activedf$lemma, collapse = " ")
    # Clark: Building a result by successive concatenation is inefficient,
    # but not the bottleneck here.
    rcv = c(rcv, coltext)
    print(paste("#", i, " of ", length(lemdflist), " done!"))
  }
  return(rcv)
}

lemed = GSRLem(doc[ , "paragraph"])




# If this gives you the following warning:
  # Warning message:
  #   Can't find the lexicon file, hence omitted! Please ensure this path is valid:
  # ~/Desktop/test/lib/english-lexicon.txt 
# Do not worry about it. From the documentation for the treetag() function:
  # you can omit all the following elements, because they will be filled with defaults. Of course this only makes sense if you have a working default installation.







