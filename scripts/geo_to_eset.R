#!/bin/env Rscript

#########
# USAGE Rscript geo_to_eset.Rscript <GDS507> </path/to/outdir>
# 
# Download a GEO Dataset (GDS) from GEO by Accession Number, 
# convert it to a biobase ExpressionSet and save it to
# an R object. The variable storing the ExpressionSet will
# be named 'eset'
#########

stopifnot(suppressPackageStartupMessages(require(GEOquery)))
stopifnot(suppressPackageStartupMessages(require(stringr)))

args = commandArgs(trailingOnly = TRUE)
geo.id = args[1]
outdir = args[2]
outfile = file.path(outdir, "%s.Rdata")
print(paste("GEO ID: ", geo.id))
print(paste("OUTFILE: ", outfile))

saveEset = function(eset, outfile) {
  print(paste("Storing expression set to", outfile))
  save(eset, file=outfile)
} 

geo.res = getGEO(geo.id,AnnotGPL=TRUE)
if(grepl("^GDS", geo.id)) {
  # GEO DataSet. Have to convert to eset first. 
  eset = GDS2eSet(geo.res)
  saveEset(eset, sprintf(outfile, geo.id))
} else {
  # GEO Series. Might contain multiple esets. 
  for (i in seq_along(names(geo.res))) {
    #extract GPL
    name = str_split(names(geo.res)[i], '_')[[1]][1]
    # print(sprintf(outfile, name))
    saveEset(geo.res[[i]], sprintf(outfile, name))
  }
}






