# Generic Makefile that can live in the same directory as an R package.

PKGNAME = $(shell awk '{if(/Package:/) print $$2}' DESCRIPTION)
VERSION = $(shell awk '{if(/Version:/) print $$2}' DESCRIPTION)
PKG = $(PKGNAME)_$(VERSION).tar.gz

# Helpful for debugging:
$(info R package is: $(PKG))

RFILES = $(wildcard R/*.R)
TESTFILES = $(wildcard tests/testthat/test*.R)
VIGNETTES = $(wildcard vignettes/*.Rmd)

#GEN_SCRIPT_OUTPUT = $(addsuffix .log, $(wildcard tests/testthat/scripts/script*.R))
## Log files that go with each test
#%.R.log: %.R
#	Rscript $<

# User local install
install: $(RFILES) DESCRIPTION
	R -e "devtools::document()"
	R CMD INSTALL .

test: $(TESTFILES) $(GEN_SCRIPT_OUTPUT)
	make install
	cd tests && Rscript testthat.R && cd ..

$(PKG): $(RFILES) $(TESTFILES) $(VIGNETTES) DESCRIPTION
	rm -f $(PKG)  # Otherwise it's included in build
	make install
	R CMD build .

check: $(PKG)
	R CMD check $(PKG) --as-cran

vignettes: $(VIGNETTES)
	make install
	R -e "tools::buildVignettes(dir = '.')"

clean:
	rm -rf vignettes/*.html $(PKG) *.Rcheck

# Graphviz images
%.png: %.dot
	dot -Tpng $< -o $@
