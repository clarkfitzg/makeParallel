# Not actually using these, but I may later
# GNU specific:
#RFILES := $(wildcard R/*.R)
RFILES!= ls R/*.R
TESTFILES!= ls tests/testthat/test*.R
#VIGNETTES!= ls vignettes/*.Rmd

PKG=codedoctor_0.0.1.tar.gz

install: $(RFILES)
	R -e "roxygen2::roxygenize()"
	R CMD INSTALL .

test: $(TESTFILES)
	make install
	cd tests && Rscript testthat.R && cd ..

#vignettes: $(VIGNETTES)

#docs:
#	R -e "tools::buildVignettes(dir = '.')"

$(PKG): $(RFILES) $(TESTFILES)
	R CMD build .

check: $(PKG)
	R CMD check $(PKG)
