#!/bin/env Rscript 

#############
# USAGE:
#   run_bioqc.R <outputDir> <gmtFile> <chunkFile> [<cutoff=0.1>]
# where chunkFile is a file containing paths to Rdata objects storing
# ExpressionSets, one file per line. The ExpressionSet in the Rdata object
# must be named 'eset_res'. 
#
# The script runs BioQC on each expression set and stores the raw 
# p-values as data tables. 
#############


stopifnot(suppressPackageStartupMessages(require(tools)))
stopifnot(suppressPackageStartupMessages(require(Biobase)))
stopifnot(suppressPackageStartupMessages(require(BioQC)))
stopifnot(suppressPackageStartupMessages(require(assertthat)))
stopifnot(suppressPackageStartupMessages(require(readr)))
source("lib/lib.R")
source("lib/db_io.R")
source("lib/geo_annotation.R")


args = commandArgs(trailingOnly=TRUE)

chunkFile = args[3]
gmtFile = args[2]
cutoff = as.numeric(args[4])
if(is.na(cutoff)) {
  cutoff = 0.1
} 
outDir = args[1]
outPath = file.path(outDir, "%s_bioqc_res.tab")
outPathMelt = file.path(outDir, "%s_bioqc_res_melt.tab")
esetFiles = readLines(chunkFile)

gmt <- readGmt(gmtFile)

runFile = function(esetFile) {
  load(esetFile)
  # run BioQC
  if(!all(is.na(fData(eset_res)[["BioqcGeneSymbol"]]))) {
      # filter expression set for probe ids with gene symbol only
      # Taking all probeids as background is a Bias towards each signature in general 
      # as probeids with gene symbol tend to be higher expressed in general. 
      eset_res = filter_eset(eset_res)
      bioqcRes = wmwTest(eset_res, gmt, valType="p.greater", col="BioqcGeneSymbol")
      return(bioqcRes)
  } else {
      stop("No Gene Symbols annotated. ")
  }
}

for (esetFile in esetFiles) {
  print(sprintf("%s started.", esetFile))
  tryCatch ({
    res = runFile(esetFile)
    # also save melted and filtered file for db. 
    res_mel = melt_bioqc(res, cutoff=cutoff)
    outFile = sprintf(outPath, tools::file_path_sans_ext(basename(esetFile)))
    outFileMelt = sprintf(outPathMelt, tools::file_path_sans_ext(basename(esetFile)))
    write.table(res, file=outFile)
    write_tsv(res_mel, outFileMelt, col_names=FALSE)
    print(sprintf("%s written to: %s", esetFile, outFile))
  }, 
  error=function(cond) {
    print(sprintf("%s failed: ", esetFile))
    print(cond)
  })
}


