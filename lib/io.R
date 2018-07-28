stopifnot(suppressPackageStartupMessages(require(ribiosIO)))
stopifnot(suppressPackageStartupMessages(require(Biobase)))

#' Get eset from gct file 
#' 
gct_to_eset = function(gct_file) {
  expr = read_gct_matrix(gct_file, keep.desc = TRUE)
  fdata = new("AnnotatedDataFrame", data.frame(desc=attributes(expr)$desc, row.names = rownames(expr)))
  return(new("ExpressionSet",
             exprs=expr,
             featureData=fdata))
}