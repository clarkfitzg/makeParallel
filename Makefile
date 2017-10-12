# Not actually using these, but I may later
# GNU specific:
#RFILES := $(wildcard R/*.R)
RFILES!= ls R/*.R
TESTFILES!= ls tests/testthat/test*.R
#VIGNETTES!= ls vignettes/*.Rmd


install: $(RFILES)
	R -e "roxygen2::roxygenize()"
	R CMD INSTALL .

test: $(TESTFILES)
	make install
	cd tests && Rscript testthat.R && cd ..

#vignettes: $(VIGNETTES)

docs:
	R -e "tools::buildVignettes(dir = '.')"

# Could make this more robust to do a better CRAN check, but no need yet.
build: $(RFILES)
	R CMD build .
	R CMD check 
