rmarkdown::render("assumptions.Rmd", "html_document")


rmarkdown::render("transpile.Rmd", "html_document")



Rmd = grep("Rmd", list.files(), value = TRUE)

lapply(Rmd, rmarkdown::render, "html_document")
