# Generic Makefile that can live in the same directory as an R package.

PKGNAME = $(shell awk '{if(/Package:/) print $$2}' DESCRIPTION)
VERSION = $(shell awk '{if(/Version:/) print $$2}' DESCRIPTION)
PKG = $(PKGNAME)_$(VERSION).tar.gz

# Helpful for debugging:
$(info R package is: $(PKG))

RFILES = $(wildcard R/*.R)
TESTFILES = $(wildcard tests/testthat/test*.R)
VIGNETTES = $(wildcard vignettes/*.Rmd)
GRAPHVIZ_PNGS = $(addsuffix .png, $(basename $(wildcard vignettes/*.dot)))
TEMPLATES = $(wildcard inst/templates/*.R)

#GEN_SCRIPT_OUTPUT = $(addsuffix .log, $(wildcard tests/testthat/scripts/script*.R))
## Log files that go with each test
#%.R.log: %.R
#	Rscript $<

# User local install
install: $(PKG)
	R CMD INSTALL $<

#NAMESPACE: $(RFILES)

test: $(TESTFILES) $(GEN_SCRIPT_OUTPUT)
	make install
	cd tests && Rscript testthat.R && cd ..

$(PKG): $(RFILES) $(TESTFILES) $(TEMPLATES) $(VIGNETTES) DESCRIPTION
	R -e "devtools::document()"
	rm -f $(PKG)  # Otherwise it's included in build
	R CMD build .

check: $(PKG)
	R CMD check $(PKG) --as-cran --run-dontrun

docs: $(VIGNETTES) $(GRAPHVIZ_PNGS)
	make install
	R -e "tools::buildVignettes(dir = '.')"

clean:
	rm -rf vignettes/*.html $(PKG) *.Rcheck

# Graphviz images
%.png: %.dot
	dot -Tpng $< -o $@
