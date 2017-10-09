library(koRpus)
# options(warn = -1)

loc = "..."
doc = read.csv(loc, header = TRUE, stringsAsFactors = FALSE)

# The only things you need to modify
LemmatizerSourceDir = 'C:/TreeTagger/'   # Where the lemmatizer source files live

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

# Run the lemmatizer!
LemmatizedDF = lemmatize(doc[1, "paragraph"])

# Clean Data
LemmatizedDF$lemma = as.character(LemmatizedDF$lemma)
LemmatizedDF[which(LemmatizedDF$lemma == "<unknown>"), "lemma"] = LemmatizedDF[which(LemmatizedDF$lemma == "<unknown>"), "token"]

paste(LemmatizedDF$lemma, collapse = " ")


#### Function ####

GSRLem = function(text.col){
  require(pbapply)
  lemdflist = pblapply(X = text.col, function(x) lemmatize(x))
  rcv = vector()
  for(i in 1:length(lemdflist)){
    activedf = lemdflist[[i]]
    activedf$lemma = as.character(activedf$lemma)
    activedf[which(activedf$lemma == "<unknown>"), "lemma"] = activedf[which(activedf$lemma == "<unknown>"), "token"]
    coltext = paste(activedf$lemma, collapse = " ")
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







