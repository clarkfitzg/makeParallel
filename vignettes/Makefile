PNGS = $(addsuffix .png, $(basename $(wildcard *.dot)))

review.html: $(PNGS)

# Markdown documents
%.html: %.md
	pandoc -s $< -o $@

# Graphviz images
%.png: %.dot
	dot -Tpng $< -o $@
