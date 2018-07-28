#' Functions related to extracting information from GEO studies.
#' 
#' Information retrieved from the GEO needs to be preprocessed
#' and santized before we send it into our database. 

stopifnot(suppressPackageStartupMessages(require(assertthat)))
stopifnot(suppressPackageStartupMessages(require(ribiosAnnotation)))
stopifnot(suppressPackageStartupMessages(require(ribiosUtils)))
stopifnot(suppressPackageStartupMessages(require(stringr)))
stopifnot(suppressPackageStartupMessages(require(readr)))


#' Retrieve Gene Symbols for BioQC with the Bioconductor packages. 
#' 
#' @param eset
#' @param platform.id
#' @return eset with addtional BioqcGeneSymbol column. 
attachGeneSymbols = function(eset, platform.id=NULL) {
  annotation.package = dbGetQuery(mydb, "select bioc_package from bioqc_gpl where gpl = ?", platform.id)
  if(nrow(annotation.package) > 0 && !is.na(annotation.package[1,1])) {
    assert_that(nrow(annotation.package) == 1)
    package.name = sprintf("%s.db", annotation.package[1,1])
    stopifnot(suppressPackageStartupMessages(require(package.name, character.only=TRUE)))
    fdata = fData(eset)
    gene.ids = select(get(package.name), keys=as.character(fdata$ID), columns=c("ENTREZID"), keytype="PROBEID")
    # returns a 1:many mapping. Use matchColumn to resolve that
    gene.ids.matched = matchColumn(fdata$ID, gene.ids, "PROBEID", multi=FALSE)
    ortholog.res = annotateHumanOrthologs(gene.ids.matched$ENTREZID)
    gene.symbols.orth = matchColumn(gene.ids.matched$ENTREZID, ortholog.res, "OrigGeneID", multi=FALSE)
    # save back to fData
    fdata = cbind(fdata, data.frame(BioqcGeneSymbol=gene.symbols.orth$GeneSymbol))
    fData(eset) = fdata
    return(eset)
  } else {
    stop(sprintf("Platform ID not found in database: %s", platform.id))
  } 
}

#' Attach human orthologous symbols
#'
attachOrthologousSymbols = function(eset) { 
  fdata = fData(eset)
  gene.ids = fdata[,"Gene ID"]
  gene.ids = sapply(gene.ids, function(x) {str_replace(x, "///(.*)", "")}) # strip multiple gene symbols 
  gene.orth = annotateHumanOrthologs(gene.ids)
  gene.orth.m = matchColumn(gene.ids, gene.orth, "OrigGeneID", multi=FALSE)
  fdata = cbind(fdata, data.frame(BioqcGeneSymbol=gene.orth.m$GeneSymbol))
  fData(eset) = fdata
  return(eset)
}

geoIdFromPath = function(path) {
  pat = "((GSE|GDS)\\d+)([-_]GPL\\d+)?(.*).(.*)"  
  id = sub(pat, "\\1", basename(path))
  return(id)
}
gplFromPath = function(path) {
  pat = "(.*)(GPL\\d+)(.*).(.*)"  
  id = sub(pat, "\\2", basename(path))
  if(id == basename(path)) { 
    return ("")
  } else {
    return(id)
  }
}

#' Filter genes with annotation from expression set. 
#' 
#' This is done to have the correct background for BioQC.
#' Taking all probeids as background is a bias towards each signature in general 
#' as probeids with gene symbol tend to be higher expressed in general. 
filter_eset = function(eset) {
  gene_symbols = fData(eset)$BioqcGeneSymbol
  hgnc_symbols = read_tsv("lib/res/hgnc_symbols.tsv", col_types = cols())
  # remove lines that have no or an invalid gene symbol 
  eset = eset[(!is.na(gene_symbols)) & (gene_symbols != '-') & (gene_symbols %in% hgnc_symbols$hgnc_symbols),]
  eset = eset[keepMaxStatRowInd(exprs(eset), fData(eset)$BioqcGeneSymbol),]
  return(eset)
}

