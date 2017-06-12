# Not actually using these, but I may later
# GNU specific:
#RFILES := $(wildcard R/*.R)
RFILES!= ls R/*.R
TESTFILES!= ls tests/testthat/test*.R


test:
	R CMD INSTALL .
	cd tests && Rscript testthat.R && cd ..

# Updates documentation and does a local install
docs:
	R -e "roxygen2::roxygenize()"

# Could make this more robust to do a better CRAN check, but no need yet.
#build: $(RFILES)
#	R CMD build .
#	R CMD check 
