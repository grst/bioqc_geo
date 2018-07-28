#!/bin/env Rscript 

#############
# USAGE:
#   run_bioqc.R <outputDir> <chunkFile> 
# where chunkFile is a file containing paths to Rdata objects storing
# ExpressionSets, one file per line. The ExpressionSet in the Rdata object
# must be named 'eset'. 
#
# The script annotates the human orthologs in each expression set
# and stores them as BioqcGeneSymbol in fdata. 
# Additionally, Bioqc is run to test the data is useable for BioQC. 
#############


stopifnot(suppressPackageStartupMessages(require(tools)))
stopifnot(suppressPackageStartupMessages(require(Biobase)))
stopifnot(suppressPackageStartupMessages(require(BioQC)))
stopifnot(suppressPackageStartupMessages(require(ribiosAnnotation)))
stopifnot(suppressPackageStartupMessages(require(assertthat)))
source("lib/lib.R")
source("lib/geo_annotation.R")
# source("lib/db.R")

# options(error = quote({
#   dump.frames("ribios.dump", to.file = TRUE)
#   quit(save = "no", status = 1L)
# }))

args = commandArgs(trailingOnly=TRUE)

chunkFile = args[2]
outDir = args[1]
stopifnot(file.exists(chunkFile))
stopifnot(dir.exists(outDir))
outPath = file.path(outDir, "%s")
esetFiles = readLines(chunkFile)

gmtFile = system.file("extdata/exp.tissuemark.affy.roche.symbols.gmt", package="BioQC")
gmt <- readGmt(gmtFile)

runFile = function(esetFile) {
  load(esetFile)
  # assert_that(length(levels(as.factor(pData(eset)$platform_id))) == 1)
  # platform.id = as.character(pData(eset)[1, 'platform_id'])
  
  eset = attachOrthologousSymbols(eset)
  
  # run BioQC
  if(!all(is.na(fData(eset)[["BioqcGeneSymbol"]]))) {
    # test if bioqc succeeds
    bioqcRes = wmwTest(eset, gmt, valType="p.greater", col="BioqcGeneSymbol")
    return(eset)
  } else {
    stop("Gene Symbols could not be annotated.")
  }
}

for (esetFile in esetFiles) {
  print(sprintf("%s started.", esetFile))
  tryCatch ({
    eset_res = runFile(esetFile)
    outFile = sprintf(outPath, basename(esetFile))
    save(eset_res, file = outFile)
    print(sprintf("%s written to: %s", esetFile, outFile))
  }, 
  error=function(cond) {
    print(sprintf("%s failed: ", esetFile))
    print(cond)
  })
}


