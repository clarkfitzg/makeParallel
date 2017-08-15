# Not actually using these, but I may later
# GNU specific:
#RFILES := $(wildcard R/*.R)
RFILES!= ls R/*.R
TESTFILES!= ls tests/testthat/test*.R
VIGNETTES!= ls vignettes/*.Rmd

all: $(RFILES) $(TESTFILES)
	R -e "roxygen2::roxygenize()"
	R CMD INSTALL .
	cd tests && Rscript testthat.R && cd ..

vignettes: $(VIGNETTES)
	R -e "tools::buildVignettes(dir = '.')"
	#R CMD Sweave 

# Could make this more robust to do a better CRAN check, but no need yet.
#build: $(RFILES)
#	R CMD build .
#	R CMD check 
