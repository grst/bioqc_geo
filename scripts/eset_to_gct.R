#!/bin/env Rscript 

#######################################################
# Script to convert an R Expression set to a 
# flatfile .gct, .fdata.tsv and .pdata.tsv
# to make data reuseable.
#
# USEAGE: 
# eset_to_gct <ESET_FILE.Rdata> <OUT_DIR> 
########################################################

stopifnot(suppressPackageStartupMessages(require(Biobase)))
stopifnot(suppressPackageStartupMessages(require(readr)))
stopifnot(suppressPackageStartupMessages(require(ribiosIO)))
stopifnot(suppressPackageStartupMessages(require(stringr)))

args = commandArgs(trailingOnly=TRUE)
eset_file = args[1]
out_dir = args[2]
file_basename = tools::file_path_sans_ext(basename(eset_file))

load(eset_file)

write_gct(exprs(eset_res), file=file.path(out_dir, str_c(file_basename, "_exprs.gct", sep="")))
write_tsv(fData(eset_res), file.path(out_dir, str_c(file_basename, "_fdata.tsv", sep="")))
write_tsv(pData(eset_res), file.path(out_dir, str_c(file_basename, "_pdata.tsv", sep="")))
