#!/bin/env Rscript

###################
# Script reads BioQC result files and writes them into the 
# postgreSQL database. 
# 
# USAGE:
#   bioqc2db.R <chunkfile>
# where <chunkfile> contains the path of one bioqc_res table file per line. 
# 
# the table files are the result of write.table(wmwTest(...))
##################

souce("lib/db_io.R")

args = commandArgs(trailingOnly=TRUE)
chunkFile = args[1]
bqcFiles = readLines(chunkFile)

for(bqcFile in bqcFiles) {
  tryCatch ({
    gse = geoIdFromPath(bqcFile)
    bioqcRes = data.table(read.table(bqcFile), keep.rownames=TRUE)
    print(sprintf("Processing %s with %d rows and %d cols", bqcFile, nrow(bioqcRes), ncol(bioqcRes)))
    bioqc2db(bioqcRes)
  }, 
  error=function(cond) {
    print(sprintf("%s failed: ", bqcFile))
    print(cond)
  })
}
