#!/bin/env Rscript

########
# USAGE:
#   Rscript plot_heatmap_and_pca.R <bioqc_res.ta> <OutputBasename>
# where eset.Rdata contains a biobase ExpressionSet. 
#
# The study applies BioQC on the expression set and saves a heatmap of
# the BioQC scores and a PCA Plot of the samples as pdf. 
########

args = commandArgs(trailingOnly = TRUE)
esetFile = args[1]
outputBasename = args[2]

#esetFile = "/homebasel/biocomp/sturmg/projects/GEO_BioQC/GDS_GPL570/GDS4074.Rdata"
#qoutputBasename = "/homebasel/biocomp/sturmg/projects/GEO_BioQC/BioQC_GEO_analysis/plots/GDS4074"

  
library(BioQC)
source("lib.R")
gmtFile = system.file("extdata/exp.tissuemark.affy.roche.symbols.gmt", package="BioQC")
gmt <- readGmt(gmtFile)
load(esetFile)

#Funciton to Apply BioQC to ExpressionSet
testEset = function(eset) {
  bioqcRes = wmwTest(eset, gmt, valType="p.greater", col="Gene symbol")
  # experimentData(eset)
  bioqcResFil <- filterPmat(bioqcRes, 1E-6)
  bioqcAbsLogRes <- absLog10p(bioqcResFil)
  # write.table(bioqcRes, file=paste(outputBasename, "_bioqc_res.tab", sep=""))
  return(bioqcAbsLogRes)
}

# run BioQC
bioqcAbsLogRes = testEset(eset)

# do heatmap
print(sprintf("writing to %s", outputBasename))
pdf(paste(outputBasename, "_heatmap.pdf", sep=""))
bioqcHeatmap(bioqcAbsLogRes, title=basename(esetFile))
dev.off()

# do PCA
pdf(paste(outputBasename, "_pca.pdf", sep=""))
esetPca(eset, title=basename(esetFile))
dev.off()
