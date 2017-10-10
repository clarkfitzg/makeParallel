# Clark: Original file consists of 80K entries to lemmatize. They can all
# happen in parallel.
# The challenge to automatically parallelize this on Windows is to realize 

# Clark- this takes about 0.5 seconds. It's 9327 words, which is much
# longer than any letter of recommendation. Do it 80K times and it becomes 11
# hours. But Jared was talking about 100 hours for the whole dataset. What
# am I missing?
#system.time(t1 <- treetag("/home/clark/data/vets/appeals_sample/1719181.txt"))


library(koRpus)
# options(warn = -1)

fname = "goodnightmoon.csv"
doc = read.csv(fname, header = TRUE, stringsAsFactors = FALSE)

# The only things you need to modify
LemmatizerSourceDir = '/home/clark/dev/tree-tagger'   # Where the lemmatizer source files live

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

# Clark: The following few lines are where he's developing the function to
# use.

# Run the lemmatizer!
LemmatizedDF = lemmatize(doc[1, "paragraph"])

# Clean Data
LemmatizedDF$lemma = as.character(LemmatizedDF$lemma)
LemmatizedDF[which(LemmatizedDF$lemma == "<unknown>"), "lemma"] = LemmatizedDF[which(LemmatizedDF$lemma == "<unknown>"), "token"]

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







