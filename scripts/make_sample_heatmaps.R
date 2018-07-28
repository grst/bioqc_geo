#!/bin/env Rscript

##########################################################
# Generate heatmaps for all samples, grouped by tissue. 
# 
# Saves output to results/heatmaps_db. 
##########################################################

source("lib/knitr.R")
source("lib/plots.R")
source("lib/db.R")
library(data.table)
library(BioQC)
library(stringr)
library(scales)
library(gtools)

args = commandArgs(trailingOnly=TRUE)
tissue_set = args[1]
cutoff = as.numeric(args[2]) # not implemented! 

out_dir = sprintf('results/heatmaps_db/%s', tissue_set)

prepend_control = Vectorize(function(str) {
  return(str_c("0", str, sep = "_"))
})

tissues = dbGetQuery(mydb, "
  select distinct tgroup
  from bioqc_tissue_set 
  where tissue_set = ?", tissue_set)

getTissueSamples = function(tissue) {
  # get all samples belonging to one tissue and filter for siginifant 
  # signatures in one sql query! 
  query = "
  select /*+ parallel(16) */ gsm
         , tgroup
         , min_found_sig_name as SIGNATURE
         , min_found_pvalue as PVALUE
    from bioqc_contamination bc
    where tgroup = ?
    and tissue_set = ?
  "
  data = data.table(dbGetQuery(mydb, query, tissue, tissue_set))
  data[,pvalue.log:=absLog10p(as.numeric(PVALUE))]
  data[,GSM:=as.character(GSM)]
  return(data)
}

getReferenceSamples = function(tissue) { 
  query = "
  select /*+ parallel(16) */ bsst.gsm
                           , bsst.tgroup
                           , bs.name as SIGNATURE
                           , br.pvalue as PVALUE
  from bioqc_selected_samples_tset bsst
  join bioqc_res br
    on br.gsm = bsst.gsm
  join bioqc_signatures bs
    on bs.id = br.signature
  where bsst.tgroup = ?
  and bsst.tissue_set = ?
  and bs.source = 'baseline_signatures.gmt'
  and bs.name in ('random_10_0', 'random_100_0', 'random_1000_1', 'awesome_housekeepers', 'enzyme_goslim')
  "
  data = data.table(dbGetQuery(mydb, query, tissue, tissue_set))
  data[,pvalue.log:=absLog10p(as.numeric(PVALUE))]
  data[,GSM:=as.character(GSM)]
  data[,SIGNATURE:=prepend_control(SIGNATURE)]
  return(data)  
}

for(tissue in tissues$TGROUP) {
  print(tissue)
  data = getTissueSamples(tissue)
  data = rbind(data, getReferenceSamples(tissue))
  data = data[mixedorder(GSM)]
  data[,GSM:=factor(GSM, levels=unique(GSM))]
  data[,SIGNATURE:=factor(SIGNATURE, levels=sort(unique(SIGNATURE), decreasing = TRUE))]
  hm.palette <- colorRampPalette(rev(brewer.pal(11, 'Spectral')), space='Lab')  
  sampids = levels(data$GSM)
 
  pdf(file=sprintf("%s/%s.pdf", out_dir, tissue),
      width=min(nrow(data)*.3 + 5, 30),
      height=length(levels(data$SIGNATURE))*.33+2)
  for (i in seq(1, length(sampids), 70)) {
    print(ggplot(data=data[GSM %in% sampids[i:(i+70)], ], aes(x=GSM, y=SIGNATURE, fill=pvalue.log)) + 
            geom_tile() +
            coord_equal() +
            scale_fill_gradientn(colours = hm.palette(100), limits=c(0, 30), oob=squish) +
            scale_y_discrete(drop=FALSE) + 
            theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
            ggtitle(tissue))
  }
  dev.off()
}
